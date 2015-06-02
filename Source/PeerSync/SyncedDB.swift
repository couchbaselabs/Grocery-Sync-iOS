//
//  SyncedDB.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/20/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Syncs with a remote database on a peer, pulling docs from it whenever it changes. */
public class SyncedDB : Printable {

    public weak var mgr: PairingManager?
    public let peer: OnlinePeer
    public let db: CBLDatabase

    private var latestSequenceSeen: UInt64 = 0
    private var sequenceBeingSynced: UInt64 = 0

    init(mgr: PairingManager, peer: OnlinePeer, database: CBLDatabase) {
        self.mgr = mgr
        self.peer = peer
        self.db = database
        self.latestSequenceSeen = peer.latestSequence

        onlineObs = peer.observe(keyPath: "online") { [unowned self] in
            if !self.peer.online {
                println("\(self): Went offline")
                self.stop()
                self.mgr?.syncedDBWentOffline(self)
            }
        }
        txtObs = peer.observe(keyPath: "txtRecord") { [unowned self] in
            if let seq = peer.txtRecord["seq"]?.toInt() {
                self.gotLatestSequence(UInt64(seq))
            }
        }
        println("\(self): Added \(peer); latest seq=\(latestSequenceSeen)")
    }

    public var description: String { return "SyncedDB[\(peer.nickname)]" }

    private func gotLatestSequence(seq: UInt64) {
        println("\(self): Got latest seq=\(seq)")
        if seq > latestSequenceSeen {
            latestSequenceSeen = seq
            triggerPull()
        }
    }

    func stop() {
        println("\(self): Stopping")
        if let pull = currentPull {
            currentPull = nil
            pullObs?.stop()
            pull.stop()
        }
        pulling = false
        pullAgain = false
        onlineObs?.stop()
        txtObs?.stop()
    }

    //// Replication:

    // Starting point of a replication
    private func triggerPull() {
        if pulling {
            if currentPull != nil {
                pullAgain = true // remember to pull again after current pull stops
            }
            return
        }

        println("\(self): Resolving address")
        pulling = true
        peer.resolve() {
            switch $0 {
            case .HostName(let hostName):
                // Got the hostname, now start the replication:
                self.sequenceBeingSynced = self.latestSequenceSeen
                let url = self.makeURL(hostName)
                let pull = self.db.createPullReplication(url)!
                println("\(self): Pulling from <\(url)>")
                self.currentPull = pull
                self.pullObs = pull.observe(keyPath: "status") { [unowned self] in
                    self.pullStatusChanged()
                }
                pull.start()
            case .Error(let error):
                // Hostname resolution failed:
                println("\(self): Resolve failed: \(error.localizedDescription)")
                self.pulling = false
                self.pullAgain = false
            }
        }
    }

    // Called when replication status property changes
    private func pullStatusChanged() {
        switch currentPull!.status {
        case .Stopped:
            if let error = currentPull!.lastError {
                println("\(self): Replication stopped with error \(error.localizedDescription)")
            } else {
                println("\(self): Replication finished")
                peer.latestSequence = sequenceBeingSynced
                mgr?.syncedDBUpdatedLatestSequence(self)
            }
            pullObs?.stop()
            currentPull = nil
            pulling = false
            if pullAgain {
                pullAgain = false
                triggerPull()
            }
        default:
            break
        }
    }

    // Subroutine to construct the peer's database's URL:
    private func makeURL(hostName: String) -> NSURL {
        var components = NSURLComponents()
        components.scheme = "http" //WORKAROUND: Use "https" once it's working on the listener side
        components.host = hostName
        components.port = peer.port
        components.path = "/" + db.name
        return components.URL!
    }

    private var pulling = false
    private var pullAgain = false
    private var currentPull: CBLReplication? = nil

    private var onlineObs: Observer? = nil
    private var txtObs: Observer? = nil
    private var pullObs: Observer?
}