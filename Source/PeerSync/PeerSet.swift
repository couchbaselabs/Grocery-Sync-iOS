//
//  PeerSet.swift
//  GrocerySync
//
//  Created by Jens Alfke on 6/1/15.
//
//

import Foundation


/** A set of Peers, uniqued by UUID */
public struct PeerSet : SequenceType, Equatable, Printable {

    public init() { }

    public var peers: [Peer] {
        return [Peer](byUUID.values)
    }

    public var UUIDs: Set<String> {
        return Set<String>(byUUID.keys)
    }

    public subscript(uuid: String) -> Peer? {
        return byUUID[uuid]
    }

    public func contains(peer: Peer) -> Bool {
        return byUUID[peer.UUID] != nil
    }

    public mutating func add(peer: Peer) {
        byUUID[peer.UUID] = peer
    }

    public mutating func remove(peer: Peer) -> Bool {
        return byUUID.removeValueForKey(peer.UUID) != nil
    }

    public func filter(predicate: Peer->Bool) -> PeerSet {
        var s = PeerSet()
        for peer in self {
            if predicate(peer) {
                s += peer
            }
        }
        return s
    }

    public func itemsNotIn(set: PeerSet) -> SequenceOf<Peer> {
        return SequenceOf<Peer>( byUUID.values.filter {!set.contains($0)} )
    }

    private var byUUID = [String:Peer]()

    // SequenceType protocol:
    public typealias Generator = MapSequenceGenerator<DictionaryGenerator<String, Peer>, Peer>
    public func generate() -> Generator {
        return byUUID.values.generate()
    }

    // Printable protocol:
    public var description: String {
        return "PeerSet\(peers)"
    }
}


public func == (a: PeerSet, b: PeerSet) -> Bool {
    return a.byUUID == b.byUUID
}

public func += (inout set: PeerSet, peer: Peer) {
    set.add(peer)
}

public func -= (inout set: PeerSet, peer: Peer) {
    set.remove(peer)
}

public func ^= (inout set: PeerSet, peer: Peer) {
    if !set.remove(peer) {
        set.add(peer)
    }
}
