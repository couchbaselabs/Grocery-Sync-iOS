//
//  DemoAppDelegate.m
//  Couchbase Mobile
//
//  Created by Jan Lehnardt on 27/11/2010.
//  Copyright 2011 Couchbase, Inc.
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
//

#import "DemoAppDelegate.h"
#import "RootViewController.h"
#import <CouchCocoa/CouchCocoa.h>

#define kDefaultSyncDbURL @"http://couchbase.iriscouch.com/grocery-sync"


@interface DemoAppDelegate ()
-(void)showSplash;
-(void)removeSplash;
@end


@implementation DemoAppDelegate


@synthesize window;
@synthesize navigationController;
@synthesize database;


// Override point for customization after application launch.
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register the default value of the pref for the remote database URL to sync with:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appdefaults = [NSDictionary dictionaryWithObject:kDefaultSyncDbURL
                                                            forKey:@"syncpoint"];
    [defaults registerDefaults:appdefaults];
    [defaults synchronize];

    // Add the navigation controller's view to the window and display.
	[window addSubview:navigationController.view];
	[window makeKeyAndVisible];
    
    [self showSplash];

    // Start the Couchbase Server
    NSString* dbPath = [[NSBundle mainBundle] pathForResource: @"grocery-sync" ofType: @"couch"];
    NSAssert(dbPath, @"Couldn't find grocery-sync.couch");
    
    CouchbaseEmbeddedServer* cb = [[CouchbaseEmbeddedServer alloc] init];
    cb.delegate = self;
    [cb installDefaultDatabase: dbPath];
    if (![cb start]) {
        [self showAlert: @"Couldn't start Couchbase." error: cb.error fatal: YES];
    }

    return YES;
}


-(void)couchbaseDidStart:(NSURL *)serverURL {
    if (serverURL == nil) {
        [self showAlert: @"Couldn't start Couchbase." error: nil fatal: YES];
        return;
    }

#if 1    // Change to "0" to run with Couchbase Single on your local workstation (simulator only)
    CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
#else
    CouchServer *server = [[CouchServer alloc] init];
#endif
    self.database = [server databaseNamed: @"grocery-sync"];
    [server release];

    // Tell the RootViewController:
    RootViewController* root = (RootViewController*)navigationController.topViewController;
    [root useDatabase: database];

    // Take down the splash screen:
    [self removeSplash];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// CouchDB seems to get stuck when in background. exit() so we get relaunched freshly.
    // (Setting the UIApplicationExitsOnSuspend key in the Info.plist accomplishes the same goal.)

	exit(0);
}


-(void)showSplash {
    // Show the splash screen until Couchbase starts up:
    UIImage *splash = [UIImage imageNamed:@"Default.png"];
    splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20,
                                                               splash.size.width,
                                                               splash.size.height)];
    splashView.image = splash;
	[self.window addSubview:splashView];
}


-(void)removeSplash {
	[splashView removeFromSuperview];
	[splashView release];
    splashView = nil;
}


// Display an error alert, without blocking.
// If 'fatal' is true, the app will quit when it's pressed.
- (void)showAlert: (NSString*)message error: (NSError*)error fatal: (BOOL)fatal {
    if (error) {
        message = [NSString stringWithFormat: @"%@\n\n%@", message, error.localizedFailureReason];
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Fatal Error"
                                                    message: message
                                                   delegate: (fatal ? self : nil)
                                          cancelButtonTitle: (fatal ? @"Quit" : @"Sorry")
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    exit(0);
}


- (void)dealloc {
	[splashView release];
	[navigationController release];
	[window release];
    [database release];
	[super dealloc];
}


@end
