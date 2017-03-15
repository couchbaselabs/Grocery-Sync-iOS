## Grocery Sync with OIDC for iOS (Objective-C version)

This is a simple demo app showing how to use the [Couchbase Lite][1] framework to embed a nonrelational ("NoSQL"), document-oriented database in an iOS app and sync it with a database server in "the cloud".

_If you prefer developing in Swift, click [here](https://github.com/couchbaselabs/Grocery-Sync-iOS/tree/swift)!_

Here's the "user story":

> So this dude is at the grocery store picking up produce and checking it off on his phone. He's all proud looking when he is about to check off the last item on the list, but then ... suddenly new items start appearing. Cut to his wife at home with the kids, and she's adding items.

> "Okra? Ok. Coconut milk? But I already got regular milk!" He checks them off as he goes. Cut to his wife who sees them marked done; she gets a big grin and starts adding cookies and ice cream and paper towels or whatever.

The app just presents a simple editable list of textual items with checkboxes, which are stored persistently in a local database, and shared in realtime with all other users who are synced with the same cloud database.

For demo purposes, the app is hardcoded to sync with a specific database on a server run by Couchbase. You can (and should) easily modify it to sync with a database you create on a [Couchbase Sync Gateway][7]. Instructions for that are below.

## Building & Running The App

These instructions assume you are familiar with building and running an iOS app.

If you have questions or get stuck or just want to say hi, please visit the [Mobile-Couchbase group][4] on Google Groups.

Prerequisite: Xcode 6.0 or later with an iOS SDK.

### Get the main repository

    git clone git://github.com/couchbaselabs/Grocery-Sync-iOS.git

Note: If you want the Swift version, run `git checkout swift`.

### Get the Couchbase Lite framework

1. [Download][1] Couchbase Lite for iOS.
2. Copy `CouchbaseLite.framework` into the `Frameworks` directory of this repo.
3. Copy `Extras/OpenIDConnectUI` into the `Frameworks/Extras` directory of this repo.

### Open the Xcode workspace

    open GrocerySync.xcodeproj

### Build and run

1. Select the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.

## Using A Local Sync Gateway

If you've installed Couchbase Server and the [Couchbase Sync Gateway][7], you can easily configure
Grocery Sync to sync locally instead of with the remote server.

(For help setting up the Sync Gateway, [read the getting started guide][8].)

1. Create a Couchbase Server bucket named `grocery-sync`.
2. If Couchbase Server is not running on the same computer as the Sync Gateway, edit the `sync_gateway_config.json` file in this directory and enter the correct server URL.
3. Start the Sync Gateway using the supplied configuration file: `sync_gateway sync_gateway_config.json`
4. Edit `DemoAppDelegate.m` and change the value of `kServerDbURL` to have the hostname/address and port of the Sync Gateway. Make sure to specify the public API port (4984) not the admin port (4985).
5. Build and run Grocery Sync.

## Adding Couchbase Lite to your existing Xcode project

Please see the documentation for [Couchbase Lite][6].


## License

Released under the Apache license, 2.0.

Copyright 2011-2014, Couchbase, Inc.

[1]: http://www.couchbase.com/download#cb-mobile
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[6]: http://docs.couchbase.com/couchbase-lite/cbl-ios/#adding-couchbase-lite-to-your-app
[7]: http://www.couchbase.com/mobile#sync-gateway
[8]: http://developer.couchbase.com/mobile/develop/guides/sync-gateway/index.html