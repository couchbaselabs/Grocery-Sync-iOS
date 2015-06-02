//
//  PeerSyncManager.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/22/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Top-level manager for PeerSync app. */
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

    public var nickname: String? {
        get {
            return nick
        }
        set(newNick) {
            if newNick != nick {
                nick = newNick
                var doc = database.existingLocalDocumentWithID("identity") ?? [:]
                doc["nickname"] = newNick
                var error: NSError?
                if database.putLocalDocument(doc, withID: "identity", error: &error) {
                    println("PeerSyncManager: Saved new nickname '\(newNick)'")
                } else {
                    println("PeerSyncManager: Couldn't save identity to db: \(error)")
                }
            }
        }
    }

    public var offlinePairedPeers: PeerSet {
        var paired = pairing.pairings
        for peer in peerBrowser.peers {
            paired.remove(peer)
        }
        return paired
    }

    public func start() -> NSError? {
        println("PeerSyncManager: ---- START ----")
        assert(nickname != nil, "No nickname set")
        var err: NSError?
        sharer = DatabaseSharer(database: database, nickname: nickname!, port: port, error: &err)
        if sharer == nil {
            return err
        }
        if let error = sharer?.start() {
            sharer = nil
            return nil
        }

        peerBrowser.ignoredUUID = sharer?.peerUUID
        peerBrowser.start()
        return nil
    }

    public func stop() {
        println("PeerSyncManager: ---- STOP ----")
        sharer?.stop()
        sharer = nil
        peerBrowser.stop()
    }

    public var started: Bool {
        return sharer != nil
    }

    private var sharer: DatabaseSharer? = nil
}
