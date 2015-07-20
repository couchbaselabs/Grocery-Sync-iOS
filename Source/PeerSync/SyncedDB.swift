//
//  SyncedDB.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/20/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Syncs with a remote database on a peer, pulling docs from it whenever it changes. */
public class SyncedDB : CustomStringConvertible {

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
                print("\(self): Went offline")
                self.stop()
                self.mgr?.syncedDBWentOffline(self)
            }
        }
        txtObs = peer.observe(keyPath: "txtRecord") { [unowned self] in
            if let seq = peer.txtRecord["seq"], seqNum = UInt64(seq) {
                self.gotLatestSequence(seqNum)
            }
        }
        print("\(self): Added \(peer); latest seq=\(latestSequenceSeen)")
    }

    public var description: String { return "SyncedDB[\(peer.nickname)]" }

    private func gotLatestSequence(seq: UInt64) {
        print("\(self): Got latest seq=\(seq)")
        if seq > latestSequenceSeen {
            latestSequenceSeen = seq
            triggerPull()
        }
    }

    func stop() {
        print("\(self): Stopping")
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

        print("\(self): Resolving address")
        pulling = true
        peer.resolve() {
            switch $0 {
            case .HostName(let hostName):
                // Got the hostname, now start the replication:
                self.sequenceBeingSynced = self.latestSequenceSeen
                let ssl = (self.peer.txtRecord["SSL"] != nil)
                let url = self.makeURL(hostName, SSL: ssl)
                let pull = self.db.createPullReplication(url)
                if ssl {
                    // Peer's UUID is the SHA-1 digest of its SSL cert, so pin to that:
                    pull.customProperties = ["pinnedCert": self.peer.UUID]
                }
                print("\(self): Pulling from <\(url)> for UUID \(self.peer.UUID)")
                self.currentPull = pull
                self.pullObs = pull.observe(keyPath: "status") { [unowned self] in
                    self.pullStatusChanged()
                }
                pull.start()
            case .Error(let error):
                // Hostname resolution failed:
                print("\(self): Resolve failed: \(error.localizedDescription)")
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
                print("\(self): Replication stopped with error \(error.localizedDescription)")
            } else {
                print("\(self): Replication finished")
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
    private func makeURL(hostName: String, SSL ssl: Bool) -> NSURL {
        let components = NSURLComponents()
        components.scheme = (ssl ? "https" : "http")
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