## Grocery Sync for iOS

This is a simple demo app showing how to use the [Couchbase Lite][1] framework to embed a nonrelational ("NoSQL"), document-oriented database in an iOS app and sync it with a database server in "the cloud".

Here's the "user story":

> "So this dude is at the grocery store picking up produce and checking it off on his phone. He's all proud looking when he is about to check off the last item on the list, but then ... suddenly new items start appearing. Cut to his wife at home with the kids, and she's adding items.

> "'Okra? Ok. Coconut milk? But I already got regular milk!' He checks them off as he goes. Cut to his wife who sees them marked done; she gets a big grin and starts adding cookies and ice cream and paper towels or whatever."

The app just presents a simple editable list of textual items with checkboxes, which are stored persistently in a local database, and shared in realtime with all other users who are synced with the same cloud database.

Syncing is not enabled by default. To enable it, press the "Configure" button and enter the URL of a [Couchbase Sync Gateway](http://www.couchbase.com/communities/couchbase-sync-gateway) (or [Couchbase Cloud](http://console.couchbasecloud.com/index/), or [Apache CouchDB][2]) database. For more info about setting up the Sync Gateway, [read the getting started guide](https://github.com/couchbase/sync_gateway/wiki/Installing-And-Upgrading).

## Building & Running The App

These instructions assume you are familiar with building and running an iOS app.

If you have questions or get stuck or just want to say hi, please visit the [Mobile-Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.6 or later with the SDK for iOS 6 or later.

### Get the main repository

    git clone git://github.com/couchbaselabs/iOS-Couchbase-Demo.git

### Get the Couchbase Lite framework

1. [Download][1] Couchbase Lite for iOS.
2. Copy `CouchbaseLite.framework` (for iOS, not Mac OS!) into the `Frameworks` directory of this repo.

### Open the Xcode workspace

    open CouchDemo.xcworkspace

### Build and run

1. Select the "CouchDemo" scheme and the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.


## Adding Couchbase Lite to your existing Xcode project

Please see the documentation for [Couchbase Lite][6].


## License

Released under the Apache license, 2.0.

Copyright 2011-2013, Couchbase, Inc.

[1]: http://www.couchbase.com/communities/couchbase-lite
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[5]: https://github.com/couchbase/couchbase-lite-ios/wiki/Building-Couchbase-Lite#building-the-framework
[6]: http://docs.couchbase.com/couchbase-lite/cbl-ios/#adding-couchbase-lite-to-your-app