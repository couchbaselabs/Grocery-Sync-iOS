//
//  PeerSyncManager.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/22/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Top-level manager for PeerSync. Your app should instantiate one of these for each CBLDatabase
    for which it wants to enable P2P sync.*/
public class PeerSyncManager {

    public let database: CBLDatabase!
    public let peerBrowser: PeerBrowser
    public let pairing: PairingManager!

    public var port: UInt16 = DatabaseSharer.kDefaultPort

    public init(database: CBLDatabase) {
        self.database = database
        self.peerBrowser = PeerBrowser(serviceType: DatabaseSharer.kServiceType)
        self.pairing = PairingManager(database: database, peerBrowser: peerBrowser)

        if let doc = database.existingLocalDocumentWithID("identity") {
            nick = doc["nickname"] as? String
        }
    }

    private var nick: String?

    /** The visible name the app will publish, which will be visible to other users browsing peers.
        You should probably let the user pick this. The value is saved persistently. */
    public var nickname: String? {
        get {
            return nick
        }
        set(newNick) {
            if newNick != nick {
                nick = newNick
                var doc = database.existingLocalDocumentWithID("identity") ?? [:]
                doc["nickname"] = newNick
                do {
                    try database.putLocalDocument(doc, withID: "identity")
                    print("PeerSyncManager: Saved new nickname '\(newNick)'")
                } catch let error as NSError {
                    print("PeerSyncManager: Couldn't save identity to db: \(error)")
                }
            }
        }
    }

    /** The set of Peers that are paired (being followed / synced from) but not online. */
    public var offlinePairedPeers: PeerSet {
        var paired = pairing.pairings
        for peer in peerBrowser.peers {
            paired.remove(peer)
        }
        return paired
    }

    /** Starts actively sharing and syncing. */
    public func start() throws {
        print("PeerSyncManager: ---- START ----")
        assert(nickname != nil, "No nickname set")
        let newSharer = try DatabaseSharer(database: database, nickname: nickname!, port: port)
        try newSharer.start()
        sharer = newSharer
        peerBrowser.ignoredUUID = sharer?.peerUUID
        peerBrowser.start()
    }

    /** Pauses sharing/syncing. On iOS you should call this when the app is suspended, and then
        call start() again when the app reactivates. */
    public func stop() {
        print("PeerSyncManager: ---- STOP ----")
        sharer?.stop()
        sharer = nil
        peerBrowser.stop()
    }

    public var started: Bool {
        return sharer != nil
    }

    private var sharer: DatabaseSharer? = nil
}
