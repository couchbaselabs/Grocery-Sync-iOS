//
//  Utilities.swift
//  swift-couchbaselite
//
//  Created by Jens Alfke on 9/17/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

import Foundation


extension CBLView {
    // Just reorders the parameters to take advantage of Swift's trailing-block syntax.
    func setMapBlock(version: String, mapBlock: CBLMapBlock) -> Bool {
        return setMapBlock(mapBlock, version: version)
    }
}

extension NSDate {
    class func withJSONObject(jsonObj: AnyObject) -> NSDate? {
        return CBLJSON.dateWithJSONObject(jsonObj)
    }
}
