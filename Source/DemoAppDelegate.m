//
//  DemoAppDelegate.m
//  Grocery Sync
//
//  Copyright 2011-2014 Couchbase, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

// NOTE: This file contains "pragma mark" markers highlighting the Couchbase Lite
// operations. You can easily find these by pulling down the Xcode methods menu above.

#import "DemoAppDelegate.h"
#import "RootViewController.h"

#import <Couchbaselite/CouchbaseLite.h> // NOTE: If this import fails, make sure you have copied
// (or symlinked) CouchbaseLite.framework into the "Frameworks" subdirectory, as per the README.

// The name of the local database the app will create. This name is mostly arbitrary, but must not
// be changed after deploying your app, or users will lose their data!
// (Note that database names cannot contain uppercase letters.)
#define kDatabaseName @"grocery-sync"

// The remote database URL to sync with. This is preconfigured with a sample database we maintain.
// In your own apps you will of course want to set this to a database you run, on your own Sync
// Gateway instance.
#define kServerDbURL @"http://demo.mobile.couchbase.com/grocery-sync/"


@implementation DemoAppDelegate
{
    NSURL* remoteSyncURL;
    CBLReplication* _pull;
    CBLReplication* _push;
    NSError* _syncError;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
}

@synthesize database;


// Override point for customization after application launch.
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Add the navigation controller's view to the window and display it:
	[window addSubview:navigationController.view];
	[window makeKeyAndVisible];

#pragma mark Initialize Couchbase Lite and find/create my database:
    NSError* error;
    self.database = [[CBLManager sharedInstance] databaseNamed: kDatabaseName error: &error];
    if (!self.database) {
        [self showAlert: @"Couldn't open database" error: error fatal: YES];
        return NO;
    }
    
    // Tell the RootViewController about the database:
    window.rootViewController = navigationController;
    [self.rootViewController useDatabase: database];

#ifdef kServerDbURL
#pragma mark Initialize bidirectional continuous sync:
    NSURL* serverDbURL = [NSURL URLWithString: kServerDbURL];
    _pull = [database createPullReplication: serverDbURL];
    _push = [database createPushReplication: serverDbURL];
    _pull.continuous = _push.continuous = YES;
    // Observe replication progress changes, in both directions:
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver: self selector: @selector(replicationProgress:)
                 name: kCBLReplicationChangeNotification object: _pull];
    [nctr addObserver: self selector: @selector(replicationProgress:)
                 name: kCBLReplicationChangeNotification object: _push];
    [_push start];
    [_pull start];
#endif

    return YES;
}


- (RootViewController*) rootViewController {
    return (RootViewController*)navigationController.topViewController;
}


// Called in response to replication-change notifications. Updates the progress UI.
#pragma mark Observe sync progress
- (void) replicationProgress: (NSNotificationCenter*)n {
    if (_pull.status == kCBLReplicationActive || _push.status == kCBLReplicationActive) {
        // Sync is active -- aggregate the progress of both replications and compute a fraction:
        unsigned completed = _pull.completedChangesCount + _push.completedChangesCount;
        unsigned total = _pull.changesCount+ _push.changesCount;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        // Update the progress bar, avoiding divide-by-zero exceptions:
        [self.rootViewController showSyncStatus: (completed / (float)MAX(total, 1u))];
    } else {
        // Sync is idle -- hide the progress bar and show the config button:
        NSLog(@"SYNC idle");
        [self.rootViewController hideSyncStatus];
    }

    // Check for any change in error status and display new errors:
    NSError* error = _pull.lastError ? _pull.lastError : _push.lastError;
    if (error != _syncError) {
        _syncError = error;
        if (error) {
            [self showAlert: @"Error syncing" error: error fatal: NO];
        }
    }
}


// Display an error alert, without blocking.
// If 'fatal' is true, the app will quit when it's dismissed.
- (void)showAlert: (NSString*)message error: (NSError*)error fatal: (BOOL)fatal {
    if (error) {
        message = [message stringByAppendingFormat: @"\n\n%@", error.localizedDescription];
    }
    NSLog(@"ALERT: %@ (error=%@)", message, error);
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: (fatal ? @"Fatal Error" : @"Error")
                                                    message: message
                                                   delegate: (fatal ? self : nil)
                                          cancelButtonTitle: (fatal ? @"Quit" : @"Sorry")
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    exit(0);
}




@end
