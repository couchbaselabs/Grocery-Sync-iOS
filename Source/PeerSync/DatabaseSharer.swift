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

    private let ssl : Bool

    public init(database: CBLDatabase, nickname: String, port: UInt16 = kDefaultPort, ssl: Bool = true) throws {
        // Get or create a persistent UUID:

        // Create the CBL listener:
        db = database
        listener = CBLListener(manager: db.manager, port: port)
        //listener.readOnly = true //WORKAROUND: This prevents CBL 1.1 clients from storing checkpoints (#726)

        self.ssl = ssl
        if (ssl) {
            do {
                try listener.setAnonymousSSLIdentityWithLabel("peersync")
            } catch {
                assert(false, "Unable to get SSL identity");
            }
        }

        if let certDigest = listener.SSLIdentityDigest {
            // Use SHA-1 digest of my SSL cert as my UUID:
            peerUUID = dataToHex(certDigest)
        } else if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("PeerUUID") {
            peerUUID = uuid
        } else {
            // If not using SSL, just make up a persistent UUID:
            peerUUID = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
            NSUserDefaults.standardUserDefaults().setObject(peerUUID, forKey: "PeerUUID")
        }

        let serviceName = OnlinePeer.createServiceName(nickname, UUID: peerUUID)
        listener.setBonjourName(serviceName, type: DatabaseSharer.kServiceType)

        print("DatabaseSharer: My UUID is '\(peerUUID)'")
        print("DatabaseSharer: Bonjour name is '\(serviceName)'")
        print("DatabaseSharer: Sharing at <\(listener.URL)>")

        // Watch for database changes:
        dbObserver = db.observe(notificationName: kCBLDatabaseChangeNotification) { [unowned self] notification in
            self.dbChanged(notification)
        }
    }

    /** Starts sharing. */
    public func start() throws {
        try listener.start()
        print("DatabaseSharer: Sharing database...");
        self.updateTXT()
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
        var txt = ["seq": "\(latestSequence)"]
        if ssl {
            txt["SSL"] = ""
        }
        listener.TXTRecordDictionary = txt
    }

    deinit {
        listener.stop()
        dbObserver?.stop()
    }

    private let db: CBLDatabase
    private let listener: CBLListener
    private var dbObserver: Observer?

}


private let digits: [UnicodeScalar] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

private func dataToHex(data: NSData) -> String {
    let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(data.bytes), count: data.length)
    var hex = ""
    hex.reserveCapacity(2*bytes.count)
    for byte: UInt8 in bytes {
        hex.append(digits[Int(byte) / 16])
        hex.append(digits[Int(byte) % 16])
    }
    return hex
}
