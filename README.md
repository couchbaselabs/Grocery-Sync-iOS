## Grocery Sync for iOS

This is a simple demo app showing how to use the [Couchbase Mobile][1] framework to run [Apache CouchDB][2] on iOS. The app just presents a simple editable list of textual items, which are stored persistently in a local database, and shared in realtime via a syncpoint in the cloud.

**Keep in mind that the default is to share the globally shared grocery list.** To use a private grocery list, the user must create a password protected database and then direct Grocery Sync at it via the Settings application. URLs are specified in the form `http://username:password@myhost.iriscouch.com/grocery-sync`

So this dude is at the grocery store picking up produce and checking it off on his phone. He's all proud looking when he is about to check off the last item on the list, but then... suddenly new items start appearing. Cut to his wife at home with the kids and she's adding items.

Okra? Ok. Coconut milk. But I already got regular milk! He checks them off as he goes. Cut to his wife who sees them marked done, she gets a big grin and starts adding cookies and ice cream and paper towels or whatever.

## Getting Started

These instructions assume you are familiar with how to make an iPhone app. Please follow them fully and in order the first time you build.

If you have questions or get stuck or just want to say hi, please visit the [Mobile Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.0.2 or later with the SDK for iOS 4 or later. (It's possible the project might still work with Xcode 3, but we're not testing or supporting this anymore.)

## Building The Demo App

### Get the main repository

    git clone git://github.com/couchbaselabs/iOS-Couchbase-Demo.git

### Get the frameworks (CouchCocoa as well as the embedded Couchbase server)

1. [Download and unzip the latest][1] compiled Couchbase.framework. (Building this is messy, you probably don't want to do it yourself.)
2. Either [download and unzip the latest][5] compiled CouchCocoa.framework, or [check out the source code][6] and build it yourself. (Build the "iOS Framework" scheme, then find CouchCocoa.framework in the build output directory.)
3. Copy both Couchbase.framework and CouchCocoa.framework into the Frameworks directory of this repo.

### Open the Xcode workspace

    open CouchDemo.xcworkspace

### Build and run the demo app

1. Select the "CouchDemo" scheme and the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.

## To add the framework to your existing Xcode project

Please see the documentation on the [Couchbase Mobile][1] home page.

## License

Portions under Apache, Erlang, and other licenses.

The overall package is released under the Apache license, 2.0.

Copyright 2011, Couchbase, Inc.


[1]: http://www.couchbase.org/get/couchbase-mobile-for-ios/current
[2]: http://couchdb.apache.org
[4]: https://groups.google.com/group/mobile-couchbase
[5]: https://github.com/couchbaselabs/CouchCocoa/downloads
[6]: https://github.com/couchbaselabs/CouchCocoa/
