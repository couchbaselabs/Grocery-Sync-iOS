## Grocery Sync for iOS

This is a simple demo app showing how to use the [TouchDB][1] and [CouchCocoa][6] frameworks to embed a nonrelational ("NoSQL") [CouchDB][2]-compatible database in an iOS app and sync it with a database server in "the cloud".

Here's the "user story":

> "So this dude is at the grocery store picking up produce and checking it off on his phone. He's all proud looking when he is about to check off the last item on the list, but then ... suddenly new items start appearing. Cut to his wife at home with the kids, and she's adding items.

> "'Okra? Ok. Coconut milk? But I already got regular milk!' He checks them off as he goes. Cut to his wife who sees them marked done; she gets a big grin and starts adding cookies and ice cream and paper towels or whatever."

The app just presents a simple editable list of textual items with checkboxes, which are stored persistently in a local database, and shared in realtime with all other users who are synced with the same cloud database.

Syncing is not enabled by default. To sync, press the "Configure" button and enter the URL of a CouchDB-compatible database. Your choices for a database include:

* Signing up for a free account at [IrisCouch][8] or [Cloudant][9], or
* Installing your own instance of [Apache CouchDB](2), or
* Using a (rather anarchic) grocery list database we've set up at `http://couchbase.iriscouch.com/grocery-sync`

## Getting Started

These instructions assume you are familiar with how to make an iPhone app. Please follow them fully and in order the first time you build.

If you have questions or get stuck or just want to say hi, please visit the [Mobile Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.2 or later with the SDK for iOS 4 or later.


## Building The Demo App

### Get the main repository

    git clone git://github.com/couchbaselabs/iOS-Couchbase-Demo.git

### Get the frameworks (easy way)

1. Go to [CocoaPods site][10] and do what's said in "Install" section.
2. Type this in terminal:

    cd iOS-Couchbase-Demo
    pod install

### Get the frameworks manually if you're not lazy (CouchCocoa as well as the embedded Couchbase server)

1. Either [download a compiled build][7] of TouchDB, or [check out][1] and build it yourself (be sure to follow its README.)
2. Likewise, either [download a compiled build][5] of CouchCocoa, or [check out][6] and build it yourself (be sure to follow its README.)
3. Copy both `Couchbase.framework` and `CouchCocoa.framework` (the ones for iOS, not Mac OS!) into the `Frameworks` directory of this repo.

### Open the Xcode workspace

    open CouchDemo.xcworkspace

### Build and run the demo app

1. Select the "CouchDemo" scheme and the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.


## To add the framework to your existing Xcode project

Please see the documentation for [TouchDB][1] and [CouchCocoa][1].


## License

Released under the Apache license, 2.0.

Copyright 2011-2012, Couchbase, Inc.


[1]: https://github.com/couchbaselabs/TouchDB-iOS/
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[5]: https://github.com/couchbaselabs/CouchCocoa/downloads
[6]: https://github.com/couchbaselabs/CouchCocoa/
[7]: https://github.com/couchbaselabs/TouchDB-iOS/downloads
[8]: http://iriscouch.com
[9]: http://cloudant.com
[10]: http://cocoapods.org
