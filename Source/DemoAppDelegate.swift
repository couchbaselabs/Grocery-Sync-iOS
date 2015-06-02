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

@UIApplicationMain
class DemoAppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {
                            
    @IBOutlet var window: UIWindow?
    @IBOutlet private var navigationController: UINavigationController!

    var database: CBLDatabase!
    var peerSyncMgr: PeerSyncManager!

    func application(application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool
    {
        var db = CBLManager.sharedInstance().databaseNamed(kDatabaseName, error: nil)
        if db != nil {
            if NSUserDefaults.standardUserDefaults().boolForKey("ResetPeerSyncDB") {
                println("PeerSyncManager: *** DELETING DATABASE (ResetPeerSyncDB enabled) ***")
                db!.deleteDatabase(nil)
                db = CBLManager.sharedInstance().databaseNamed(kDatabaseName, error: nil)
            }
        }
        if db == nil {
            fatalAlert("Unable to initialize Couchbase Lite")
            return false
        }
        database = db
        peerSyncMgr = PeerSyncManager(database: database)

        window!.addSubview(navigationController.view)
        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        return true
    }

    
    func applicationDidBecomeActive(application: UIApplication) {
        if !peerSyncMgr.started {
            if peerSyncMgr.nickname == nil {
                // Can't start yet: ask for nickname first
                askForNickname()
            } else {
                peerSyncMgr.start()
            }
        }
    }

    /** If user doesn't have a nickname yet (i.e. 1st launch) prompt for one */
    func askForNickname() {
        let alert = UIAlertController(title: "What's your nickname?", message: "Choose a public nickname that will identify you to others on the LAN.", preferredStyle: .Alert)
        var nicknameField: UITextField!
        alert.addTextFieldWithConfigurationHandler() { textField in
            nicknameField = textField
            textField.placeholder = "nickname"
        }
        alert.addAction(UIAlertAction(title: "Quit", style: .Cancel) { action in
            exit(0)
            })
        alert.addAction(UIAlertAction(title: "OK", style: .Default) { action in
            // OK, NOW we can start:
            self.peerSyncMgr.nickname = nicknameField.text
            self.peerSyncMgr.start()
            })
        navigationController.presentViewController(alert, animated: true, completion: nil)
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

    func fatalAlert(var message: String) {
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

