## Grocery Sync for iOS (Swift version)

This is a simple demo app showing how to use the [Couchbase Lite][1] framework to embed a nonrelational ("NoSQL"), document-oriented database in an iOS app and sync it with a database server in "the cloud".

Here's the "user story":

> So this dude is at the grocery store picking up produce and checking it off on his phone. He's all proud looking when he is about to check off the last item on the list, but then ... suddenly new items start appearing. Cut to his wife at home with the kids, and she's adding items.

> "Okra? Ok. Coconut milk? But I already got regular milk!" He checks them off as he goes. Cut to his wife who sees them marked done; she gets a big grin and starts adding cookies and ice cream and paper towels or whatever.

The app just presents a simple editable list of textual items with checkboxes, which are stored persistently in a local database, and shared in realtime with all other users who are synced with the same cloud database.

For demo purposes, the app is hardcoded to sync with a specific database on a server run by Couchbase. You can (and should) easily modify it to sync with a database you create on a [Couchbase Sync Gateway][7] (or [Apache CouchDB][2]) server. For more info about setting up the Sync Gateway, [read the getting started guide][8].

## Building & Running The App

These instructions assume you are familiar with building and running an iOS app.

If you have questions or get stuck or just want to say hi, please visit the [Mobile-Couchbase group][4] on Google Groups.

Prerequisite: Xcode 6.0 or later with an iOS SDK.

### Get the main repository

    git clone git://github.com/couchbaselabs/Grocery-Sync-iOS.git
    git checkout swift

### Get the Couchbase Lite framework

1. [Download][1] Couchbase Lite for iOS.
2. Copy `CouchbaseLite.framework` into the `Frameworks` directory of this repo.

### Open the Xcode workspace

    open GrocerySync.xcodeproj

### Build and run

1. Select the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.

## Adding Couchbase Lite to your existing Xcode project

Please see the documentation for [Couchbase Lite][6].

## Swift-specific notes

If you can't find the Swift source code in the project, you probably forgot to check out the "swift" branch. Please run `git checkout swift`.

The "bridging header" (`GrocerySync-Bridging-Header.h`) makes the Couchbase Lite APIs available to Swift. It simply imports the Couchbase Lite master header.

Swift's "trailing closures" feature simplifies the syntax of calling a function/method whose last parameter is a closure: the closure can go _after_ the closing paren. Unfortunately there are a few Couchbase Lite methods that take a closure but put another parameter after it. I've created a small source file `Utilities.swift` that adds some class extensions that define variants of these methods that put the closure last.

Working with JSON-parsed dictionaries can be a bit awkward in Swift due to its stricter static typing. You'll note a liberal use of `?`s in code that extracts properties from dictionaries, to avoid embarrassing fatal exceptions if a document doesn't match the expected schema. You should do the same in your apps.


## License

Released under the Apache license, 2.0.

Copyright 2011-2014, Couchbase, Inc.

[1]: http://www.couchbase.com/download#cb-mobile
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[6]: http://docs.couchbase.com/couchbase-lite/cbl-ios/#adding-couchbase-lite-to-your-app
[7]: http://www.couchbase.com/mobile#sync-gateway
[8]: http://developer.couchbase.com/mobile/develop/guides/sync-gateway/index.html