//
//  DatabaseSharer.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/18/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Runs a CBLListener to share a database, and publishes it via Bonjour, including a TXT record
    that contains the latest sequence number so that clients can detect when the db changes. */
public class DatabaseSharer {

    public static let kDefaultPort: UInt16 = 59844

    /** Bonjour service type for publishing a database */
    public static let kServiceType = "_peersync._tcp"

    /** The UUID I publish as */
    public let peerUUID: String

    public init(database: CBLDatabase, nickname: String, port: UInt16 = kDefaultPort) throws {
        // Get or create a persistent UUID:
        if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("PeerUUID") {
            peerUUID = uuid
        } else {
            peerUUID = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
            NSUserDefaults.standardUserDefaults().setObject(peerUUID, forKey: "PeerUUID")
        }

        // Create the CBL listener:
        db = database
        listener = CBLListener(manager: db.manager, port: port)
        //listener.readOnly = true //WORKAROUND: This prevents CBL 1.1 clients from storing checkpoints (#726)
        let serviceName = OnlinePeer.createServiceName(nickname, UUID: peerUUID)
        listener.setBonjourName(serviceName, type: DatabaseSharer.kServiceType)
        //listener.readOnly = true
        /* WORKAROUND: This doesn't work with CBL 1.1 (clients reject the cert as invalid: #724)
        if !listener.setAnonymousSSLIdentityWithLabel("peersync", error: outError) {
            return nil
        }*/
        print("DatabaseSharer: Service name is '\(serviceName)'")

        // Watch for database changes:
        dbObserver = db.observe(notificationName: kCBLDatabaseChangeNotification) { [unowned self] notification in
            self.dbChanged(notification)
        }
    }

    /** Starts sharing. */
    public func start() -> NSError? {
        var error: NSError?
        do {
            try listener.start()
            print("DatabaseSharer: Sharing database...");
            self.updateTXT()
            return nil
        } catch var error1 as NSError {
            error = error1
            print("DatabaseSharer: Couldn't share database: \(error)")
            return error
        }
    }

    /** Pauses sharing. */
    public func stop() {
        listener.stop()
        print("DatabaseSharer: ...Stopped sharing database");
    }

    private func dbChanged(notification: NSNotification) {
        for change in notification.userInfo?["changes"] as! [CBLDatabaseChange] {
            if change.source == nil { // ignore changes made by pull replications
                self.updateTXT()
                break
            }
        }
    }

    private func updateTXT() {
        let latestSequence = db.lastSequenceNumber
        print("DatabaseSharer: Publishing seq=\(latestSequence)")
        listener.TXTRecordDictionary = ["seq": "\(latestSequence)"]
    }

    deinit {
        listener.stop()
        dbObserver?.stop()
    }

    private let db: CBLDatabase
    private let listener: CBLListener
    private var dbObserver: Observer?

}