## Grocery Sync for iOS (Swift version, plus P2P support)

This is a simple demo app showing how to use the [Couchbase Lite][1] framework to embed a nonrelational ("NoSQL"), document-oriented database in an iOS app and sync it with a database server in "the cloud".

_To view the main README, click [here](https://github.com/couchbaselabs/Grocery-Sync-iOS/tree/master)!_

**bonjour-sync branch:** This branch adds some peer-to-peer code to allow GrocerySync apps on the same LAN to sync with each other without any server. It was used as a demo during Jens Alfke's P2P presentation at Couchbase Connect '15. The P2P code is in the "PeerSync" folder.

The basic idea is:

* Make up a persistent UUID.
* Use the Couchbase Lite listener to serve your database.
    * Advertise it over Bonjour with a service name consisting of the UUID plus a nickname.
    * Set a TXT record containing the database's latestSequenceNumber
* Use Bonjour (NSNetServiceBrowser) to browse the LAN for other instances of the P2P service.
* Allow the user to view the browsed services (by nickname) and let them pick ones to 'follow'.
* Persistently remember the set of followed UUIDs.
* Remember the latestSequenceNumber of each followed peer.
* When the peer is online and publishes a higher sequence number, trigger a one-off pull replication. Then update the saved sequence.
