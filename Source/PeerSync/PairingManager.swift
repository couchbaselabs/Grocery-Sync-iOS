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

        observer = NSNotificationCenter.defaultCenter().addObserverForName(PeerBrowser.AddedPeerNotification, object: peerBrowser, queue: nil) { n in
            if let peer = n.userInfo?["peer"] as? OnlinePeer {
                self.peerWentOnline(peer)
            }
        }
    }

    // Maps paired peer UUIDs to latest synced sequences
    public var pairings = PeerSet() {
        didSet {
            for peer in oldValue.itemsNotIn(pairings) {
                // Remove obsolete peer:
                println("PairingManager: Removing paired \(peer)")
                activeSyncedDBs.removeValueForKey(peer.UUID)?.stop()
            }
            for peer in pairings.itemsNotIn(oldValue) {
                // Register new peer:
                println("PairingManager: Adding paired \(peer)")
                if let onlinePeer = peer as? OnlinePeer {
                    if onlinePeer.online {
                        peerWentOnline(onlinePeer)
                    }
                }
            }
            savePairings()
        }
    }

    public var pairedUUIDs: Set<String> {
        return pairings.UUIDs
    }

    public func isPaired(peer: Peer) -> Bool {
        return pairings.contains(peer)
    }

    public func setPaired(peer: Peer, paired: Bool) {
        if paired {
            addPairedPeer(peer)
        } else {
            removePairedPeer(peer)
        }
    }

    public func addPairedPeer(peer: Peer) {
        if !pairings.contains(peer) {
            println("PairingManager: Adding paired \(peer)")
            pairings += peer
            savePairings()
            if let onlinePeer = peer as? OnlinePeer {
                if onlinePeer.online {
                    peerWentOnline(onlinePeer)
                }
            }
        }
    }

    public func removePairedPeer(peer: Peer) {
        if pairings.remove(peer) {
            println("PairingManager: Removing paired \(peer)")
            savePairings()
            activeSyncedDBs.removeValueForKey(peer.UUID)?.stop()
        }
    }

    //// INTERNAL:

    private func peerWentOnline(peer :OnlinePeer) {
        if let curPeer = pairings[peer.UUID] {
            println("*** Paired \(peer) went online ***")
            pairings += peer  // replace with online Peer instance
            peer.latestSequence = curPeer.latestSequence
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
    }

    private let database: CBLDatabase
    private let peerBrowser: PeerBrowser
    private var observer: NSObjectProtocol! = nil
}
