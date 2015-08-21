//
//  PeerBrowser.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/18/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


/** Bonjour browser that keeps a list of OnlinePeer instances for available peers. */
public class PeerBrowser : NSObject, NSNetServiceBrowserDelegate {

    /** Set of currently available peers (observable) */
    public dynamic private(set) var peers = [OnlinePeer]()

    /** Error that caused browsing to fail (observable) */
    public dynamic private(set) var error: NSError?

    /** You can set this to the name of a service that should be ignored, usually a service
        you're publishing yourself. */
    public var ignoredUUID: String?

    /** Initialize, given a service type to browse for. */
    public init(serviceType: String) {
        self.serviceType = serviceType
        self.browser = NSNetServiceBrowser()
        super.init()
        browser.includesPeerToPeer = true
        browser.delegate = self
    }

    public func start() {
        browser.searchForServicesOfType(serviceType, inDomain: "local.")
    }

    public func stop() {
        browser.stop()
    }

    private let serviceType: String
    private let browser: NSNetServiceBrowser

    private var peerMap = [String:OnlinePeer]()
    private var servicesToAdd = [NSNetService]()
    private var servicesToRemove = [NSNetService]()

    // NSNetServiceBrowserDelegate protocol:

    public func netServiceBrowser(sender: NSNetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        self.error = makeError(errorDict)
    }

    public func netServiceBrowser(sender: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        if let peer = OnlinePeer(service: service) {
            if peer.UUID != ignoredUUID {
                print("Browser found \(service)");
                peerMap[service.name] = peer
                peer.online = true
                if !moreComing {
                    updatePeers()
                }
                NSNotificationCenter.defaultCenter().postNotificationName(PeerBrowser.AddedPeerNotification, object: self, userInfo: ["peer": peer])
            }
        }
    }

    public func netServiceBrowser(sender: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if OnlinePeer(service: service) != nil {
            print("Browser removing \(service)");
            if let peer = peerMap.removeValueForKey(service.name) {
                peer.online = false
            }
            if !moreComing {
                updatePeers()
            }
        }
    }

    private func updatePeers() {
        peers = [OnlinePeer](peerMap.values)
    }

    /** Posted when a new peer appears. UserInfo key "peer" has the OnlinePeer object. */
    public static let AddedPeerNotification = "PeerBrowser.AddedPeer"

}


func makeError(errorDict: [NSObject : AnyObject]) -> NSError {
    let code = errorDict[NSNetServicesErrorCode]?.integerValue ?? 0
    return NSError(domain: "NSNetService", code: code, userInfo: errorDict)
}
