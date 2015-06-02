//
//  Observer.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/22/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import Foundation

/** Utility class that performs KVO. Code using this can conveniently put the listening code in
    a block/closure, and doesn't have to extend NSObject. */
public class Observer : NSObject {

    init(source: NSObject, keyPath: String, options: NSKeyValueObservingOptions = nil, onChange: ()->()) {
        self.source = source
        self.keyPath = keyPath
        self.onChange = onChange
        super.init()
        source.addObserver(self, forKeyPath: self.keyPath, options: options, context: nil)
    }

    deinit {
        source?.removeObserver(self, forKeyPath: keyPath)
    }

    /** Stops observing. */
    public func stop() {
        source?.removeObserver(self, forKeyPath: keyPath)
        source = nil
    }

    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        onChange()
    }

    private var source: NSObject?
    private let keyPath: String
    private let onChange: ()->()

}

public extension NSObject {

    /** Convenience method to create an Observer. The returned Observer needs to be kept around
        for as long as you need to observe, and should be stopped when you're done. */
    public func observe(keyPath: String, options: NSKeyValueObservingOptions = nil, onChange: ()->()) -> Observer {
        return Observer(source: self, keyPath: keyPath, options: options, onChange: onChange)
    }

}
