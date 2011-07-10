## Mobile Couchbase Demo App for iOS

This is a simple demo app showing how to use the [Couchbase Mobile][1] framework to run [Apache CouchDB][2] on iOS. The app just presents a simple editable list of textual items, which are stored persistently in a local database.

It isn't intended as a starting point for your own development; you could use it as such, but the Couchbase framework makes it pretty easy to start a new project any way you like and add Couchbase support to it, so you'll likely find that simpler than ripping out the parts of the demo app that you don't want.


## Getting Started

These instructions assume you are familiar with how to make an iPhone app. Please follow them fully and in order the first time you build.

If you have questions or get stuck or just want to say hi, please visit the [Mobile Couchbase group][4] on Google Groups.

Prerequisite: Xcode 4.0.2 or later with the SDK for iOS 4 or later. (It's possible the project might still work with Xcode 3, but we're not testing or supporting this anymore. It's difficult enough to get all the moving parts to mesh together in one version of Xcode at a time!)

## Building The Demo App

### Get the main repository

    git clone git://github.com/couchbaselabs/iOS-Couchbase-Demo.git

### Get the submodules

    cd iOS-Couchbase-Demo/
    git submodule init
    git submodule update

### Get the framework

1. Download [Couchbase.framework][5]
2. Unzip the archive if necessary
3. Move Couchbase.framework into the "Frameworks" subfolder.

### Open the Xcode workspace

    open CouchDemo.xcworkspace

### Build TouchJSON

Due to incompatble build setups, you'll have to manually build both flavors of the dependent TouchJSON library before you can build the demo app the first time:

1. Select the "TouchJSON-iphoneos" scheme and choose Product > Build.
1. Select the "TouchJSON-simulator" scheme and choose Product > Build.

You won't need to do this again unless you either clean your build or modify TouchJSON sources.

### Build and run the demo app

1. Select the "CouchDemo" scheme and the appropriate destination (an iOS device or simulator) from the pop-up menu in the Xcode toolbar.
2. Click the Run button

That's it! Now that you're set up, you can just use the Run command again after making changes to the demo code.

## To add the framework to your existing Xcode project

Please see the documentation in the [Couchbase Mobile][1] repository.

## License

Portions under Apache, Erlang, and other licenses.

The overall package is released under the Apache license, 2.0.

Copyright 2011, Couchbase, Inc.


[1]: https://github.com/couchbaselabs/iOS-Couchbase
[2]: http://couchdb.apache.org
[3]: https://github.com/couchbaselabs/iOS-Couchbase/blob/master/doc/using_mobile_couchbase.md
[4]: https://groups.google.com/group/mobile-couchbase
[5]: https://github.com/downloads/snej/iOS-Couchbase/Couchbase.framework.zip