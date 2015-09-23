//
//  Observer.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/22/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation

/** Utility class that performs both key-value observing and NSNotification observing on behalf of
    Swift objects. Code using this can conveniently put the listening code in a block/closure,
    and doesn't have to extend NSObject. */
public class Observer : NSObject {

    public init(source: NSObject, keyPath: String, options: NSKeyValueObservingOptions = [], onChange: ()->()) {
        self.source = source
        self.keyPath = keyPath
        self.onChange = onChange
        super.init()
        source.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
    }

    public init(source: NSObject?, notificationName: String?, queue: NSOperationQueue? = nil, onNotification: NSNotification->()) {
        self.keyPath = nil
        self.onChange = nil
        self.noteObserver = NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: source, queue: queue) { n in
            onNotification(n)
        }
    }

    deinit {
        stop()
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        onChange!()
    }

    /** Stops observing. */
    public func stop() {
        if let keyPath = self.keyPath {
            source?.removeObserver(self, forKeyPath: keyPath)
        }
        if let o = noteObserver {
            NSNotificationCenter.defaultCenter().removeObserver(o)
            noteObserver = nil
        }
        source = nil
    }

    private var source: NSObject?
    private let keyPath: String?
    private let onChange: (()->())?
    private var noteObserver: NSObjectProtocol?
}


public extension NSObject {

    /** Convenience method to observe the receiver's properties via KVO.
        The returned Observer needs to be kept around for as long as you need to observe,
        and should be stopped when you're done. */
    public func observe(keyPath keyPath: String, options: NSKeyValueObservingOptions = [], onChange: ()->()) -> Observer {
        return Observer(source: self, keyPath: keyPath, options: options, onChange: onChange)
    }

    /** Convenience method to observe NSNotifications posted by the receiver. 
        The returned Observer needs to be kept around for as long as you need to observe,
        and should be stopped when you're done. */
    public func observe(notificationName notificationName: String?, queue: NSOperationQueue? = nil, onNotification: NSNotification->()) -> Observer {
        return Observer(source: self, notificationName: notificationName, queue: queue, onNotification: onNotification)
    }

}
