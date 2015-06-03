//
//  PairingManager.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/21/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Remembers which peers are paired, and creates SyncedDB objects for them when they come online.
    Stores the pairing info persistently in the local database. */
public class PairingManager {

    /** All active SyncedDB instances. */
    public private(set) var activeSyncedDBs = [String:SyncedDB]()

    public init(database: CBLDatabase, peerBrowser: PeerBrowser) {
        self.database = database
        self.peerBrowser = peerBrowser
        readPairings()

        observer = peerBrowser.observe(notificationName: PeerBrowser.AddedPeerNotification) {
            [unowned self] n in
            if let peer = n.userInfo?["peer"] as? OnlinePeer {
                self.peerWentOnline(peer)
            }
        }
    }

    /** Set of Peers that I will pull from. */
    public var pairings = PeerSet() {
        didSet {
            var changed = false
            for peer in oldValue.itemsNotIn(pairings) {
                // Remove obsolete peer:
                println("PairingManager: Removing paired \(peer)")
                activeSyncedDBs.removeValueForKey(peer.UUID)?.stop()
                changed = true
            }
            for peer in pairings.itemsNotIn(oldValue) {
                // Register new peer:
                println("PairingManager: Adding paired \(peer)")
                if let onlinePeer = peer as? OnlinePeer {
                    if onlinePeer.online {
                        peerWentOnline(onlinePeer)
                    }
                    changed = true
                }
            }
            if changed {
                savePairings()
            }
        }
    }

    //// INTERNAL:

    private func peerWentOnline(peer :OnlinePeer) {
        if let curPeer = pairings[peer.UUID] {
            println("*** Paired \(peer) went online ***")
            peer.latestSequence = curPeer.latestSequence
            pairings += peer  // replace with online Peer instance
            activeSyncedDBs[peer.UUID] = SyncedDB(mgr: self, peer: peer, database: database)
        }
    }

    func syncedDBWentOffline(synced: SyncedDB) {
        activeSyncedDBs.removeValueForKey(synced.peer.UUID)
    }

    func syncedDBUpdatedLatestSequence(synced: SyncedDB) {
        savePairings()
    }

    private func readPairings() {
        var p = PeerSet()
        if let pairDoc = database.existingLocalDocumentWithID("pairings"),
            byUUID = pairDoc["UUIDs"] as? [String:AnyObject] {
                for (uuid, value) in byUUID {
                    if let info = value as? [String:AnyObject],
                        nickname = info["nick"] as? String {
                            let peer = Peer(UUID: uuid, nickname: nickname)
                            if let lastSeq = info["seq"] as? NSNumber {
                                peer.latestSequence = lastSeq.unsignedLongLongValue
                            }
                            p += peer
                    }
                }
        }
        pairings = p
        println("PairingManager: Read pairings: \(pairings)")
    }

    private func savePairings() {
        var pairDict = [String:AnyObject]()
        for peer in pairings.peers {
            let seq = NSNumber(unsignedLongLong: peer.latestSequence)
            let info: [String:AnyObject] = ["nick": peer.nickname, "seq": seq]
            pairDict[peer.UUID] = info
        }

        var pairDoc = database.existingLocalDocumentWithID("pairings") ?? [:]
        pairDoc["UUIDs"] = pairDict
        var error: NSError?
        if !database.putLocalDocument(pairDoc, withID: "pairings", error: &error) {
            println("PairingManager: Couldn't save pairings to db: \(error)")
        }
        println("PairingManager: Saved pairings: \(pairDict)")
    }

    private let database: CBLDatabase
    private let peerBrowser: PeerBrowser
    private var observer: Observer! = nil
}
