//
//  DemoAppDelegate.swift
//  Grocery Sync
//
//  Copyright (c) 2014 Couchbase Inc. All rights reserved.
//

import UIKit

// The name of the local database the app will create. This name is mostly arbitrary, but must not
// be changed after deploying your app, or users will lose their data!
// (Note that database names cannot contain uppercase letters.)
private let kDatabaseName = "grocery-sync"

// The remote database URL to sync with.
private let kServerDbURL = NSURL(string: "http://demo.mobile.couchbase.com/grocery-sync/")!
// This demo app has an NSAppTransportSecurity key in its Info.plist that allows non-SSL connections
// to the demo.mobile.couchbase.com domain, since that domain does not yet have a working SSL
// server. This is only for demo purposes! In a real application you should always secure your
// Sync Gateway or other sync server with SSL.


@UIApplicationMain
class DemoAppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {
                            
    @IBOutlet var window: UIWindow?
    @IBOutlet private var navigationController: UINavigationController!

    private var _push: CBLReplication!
    private var _pull: CBLReplication!
    private var _syncError: NSError?


    let database: CBLDatabase!


    override init() {
        database = try? CBLManager.sharedInstance().databaseNamed(kDatabaseName)
    }

    func application(application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool
    {
        window!.addSubview(navigationController.view)
        window!.makeKeyAndVisible()

        guard database != nil else {
            fatalAlert("Unable to initialize Couchbase Lite")
            return false
        }

        // Initialize replication:
        _push = setupReplication(database.createPushReplication(kServerDbURL))
        _pull = setupReplication(database.createPullReplication(kServerDbURL))
        _push.start()
        _pull.start()
        return true
    }

    
    func setupReplication(replication: CBLReplication!) -> CBLReplication! {
        if replication != nil {
            replication.continuous = true
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "replicationProgress:",
                name: kCBLReplicationChangeNotification,
                object: replication)
        }
        return replication
    }


    func replicationProgress(n: NSNotification) {
        let progressBar = (navigationController.topViewController as! RootViewController).progressBar
        if (_pull.status == CBLReplicationStatus.Active || _push.status == CBLReplicationStatus.Active) {
            // Sync is active -- aggregate the progress of both replications and compute a fraction:
            let completed = _pull.completedChangesCount + _push.completedChangesCount
            let total = _pull.changesCount + _push.changesCount
            NSLog("SYNC progress: %u / %u", completed, total)
            // Update the progress bar, avoiding divide-by-zero exceptions:
            progressBar?.progress = Float(completed) / Float(max(total, 1))
            progressBar?.hidden = false
        } else {
            // Sync is idle -- hide the progress bar:
            progressBar?.hidden = true
        }

        // Check for any change in error status and display new errors:
        let error = _pull.lastError ?? _push.lastError
        if (error != _syncError) {
            _syncError = error
            if error != nil {
                self.showAlert("Error syncing", forError: error)
            }
        }
    }


    func showAlert(var message: String, forError error: NSError?) {
        if error != nil {
            message = "\(message)\n\n\((error?.localizedDescription)!)"
        }
        NSLog("ALERT: %@ (error=%@)", message, (error ?? ""))
        let alert = UIAlertView(
            title: "Error",
            message: message,
            delegate: nil,
            cancelButtonTitle: "Sorry")
        alert.show()
    }

    func fatalAlert(message: String) {
        NSLog("ALERT: %@", message)
        let alert = UIAlertView(
            title: "Fatal Error",
            message: message,
            delegate: self,
            cancelButtonTitle: "Quit")
        alert.show()
    }

    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        exit(0)
    }

}

