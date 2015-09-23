//
//  Peer.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/19/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation


// How long to wait before giving up on a resolve
private let kResolveTimeout = 5.0


// Result of a resolve: either a hostname or an error
public enum ResolveResult {
    case HostName(String)
    case Error(NSError)
}



public class Peer : NSObject {

    /** Unique ID of this peer */
    public let UUID: String

    /** User-visible name this peer is currently using (could change in the future) */
    public let nickname: String

    public internal(set) dynamic var online = false

    var latestSequence: UInt64 = 0

    init(UUID: String, nickname: String) {
        self.UUID = UUID
        self.nickname = nickname
    }

    // Printable protocol:
    public override var description: String {
        let className = (self as? OnlinePeer != nil) ? "OnlinePeer" : "Peer"
        return "\(className)['\(nickname)', \(UUID) at #\(latestSequence)]"
    }
}

public func == (a: Peer, b: Peer) -> Bool {
    return a.UUID == b.UUID
}



public class OnlinePeer : Peer, NSNetServiceDelegate {

    public /*internal(set)*/ override dynamic var online: Bool {
        didSet {
            if !online {
                hostName = nil
                txtRecord = [:]
            }
        }
    }

    public var port: Int {
        return service.port
    }

    /** Hostname of device (observable) */
    public private(set) dynamic lazy var hostName: String? = {
        // First access to .hostName will return nil but starts the async name resolution:
        self.resolve(nil)
        return nil
    }()

    /** Asynchronously resolve the service to find its host name. The callback will be invoked
    when the hostname is resolved or an error occurs. */
    public func resolve(callback: ((ResolveResult) -> ())?) {
        if callback != nil {
            assert(resolveCallback == nil) // can only have one callback pending
            resolveCallback = callback
        }
        if !resolving {
            service.delegate = self
            service.resolveWithTimeout(kResolveTimeout)
            resolving = true
        }
    }

    /** The service's "TXT record", a small dictionary of metadata set by the peer. */
    public dynamic var txtRecord = [String:String]()

    public func monitorTXTRecord() {
        self.service.delegate = self
        self.service.startMonitoring()

    }

    public override func addObserver(observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutablePointer<Void>) {
        // Detect when .hostName or .txtRecord are being observed, and start the async lookup:
        if keyPath == "hostName" {
            _ = self.hostName
        } else if keyPath == "txtRecord" {
            monitorTXTRecord()  
        }
        super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }


    private let service: NSNetService
    private var resolving = false
    private var resolveCallback: (ResolveResult -> ())?

    init?(service: NSNetService) {
        self.service = service
        let (nick, uuid) = OnlinePeer.parseServiceName(service.name)
        super.init(UUID: uuid, nickname: nick)
        if UUID.isEmpty {
            return nil
        }
    }

    static let serviceNameRegex = try! NSRegularExpression(pattern: "^(.+?)\\s*\\[(\\w+)\\]",
        options: NSRegularExpressionOptions(rawValue: 0))

    // Parses a service name into a nickname and a UUID
    class func parseServiceName(name: NSString) -> (String, String) {
        guard let match = serviceNameRegex.firstMatchInString(name as String, options: [], range: NSMakeRange(0, name.length)) else {
            return ("","")
        }
        let nickname = name.substringWithRange(match.rangeAtIndex(1))
        let UUID = name.substringWithRange(match.rangeAtIndex(2))
        return (nickname, UUID)
    }

    class func createServiceName(nickname: String, UUID: String) -> String {
        return "\(nickname) [\(UUID)]"
    }

    // NSNetServiceDelegate protocol:

    public func netServiceDidResolveAddress(sender: NSNetService) {
        let hostName = service.hostName!
        finishedResolving(ResolveResult.HostName(hostName))
        self.hostName = hostName  // Triggers KVO
    }

    public func netService(sender: NSNetService, didNotResolve errorDict: [String: NSNumber]) {
        finishedResolving(ResolveResult.Error(makeError(errorDict)))
    }

    private func finishedResolving(result: ResolveResult) {
        //println("finished Resolving: \(result)")
        resolving = false
        if let cb = resolveCallback {
            resolveCallback = nil
            cb(result)
        }
    }

    public func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData) {
        var txt = [String:String]()
        for (key, value) in NSNetService.dictionaryFromTXTRecordData(data) {
            let value = NSString(data: (value as NSData), encoding: NSUTF8StringEncoding)
            txt[key as String] = (value as! String)
        }
        self.txtRecord = txt
    }
}
