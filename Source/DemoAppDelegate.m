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

// The name of the database the app will use.
#define kDatabaseName @"grocery-sync"

// The default remote database URL to sync with, if the user hasn't set a different one as a pref.
#define kDefaultSyncDbURL @"http://couchbase.iriscouch.com/grocery-sync"

// Set this to 1 to install a pre-built database from a ".couch" resource file on first run.
#define INSTALL_CANNED_DATABASE 0

// Define this to use a server at a specific URL, instead of the embedded Couchbase Mobile.
// This can be useful for debugging, since you can use the admin console (futon) to inspect
// or modify the database contents.
//#define USE_REMOTE_SERVER @"http://localhost:5984/"


@interface DemoAppDelegate ()
-(void)showSplash;
-(void)removeSplash;
@end


@implementation DemoAppDelegate


static CouchbaseEmbeddedServer* gCouchbaseEmbeddedServer;


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
#ifdef USE_REMOTE_SERVER
    [self performSelector: @selector(couchbaseDidStart:)
               withObject: [NSURL URLWithString: USE_REMOTE_SERVER]
               afterDelay: 0.0];
#else
    gCouchbaseEmbeddedServer = [[CouchbaseEmbeddedServer alloc] init];
    gCouchbaseEmbeddedServer.delegate = self;
#if INSTALL_CANNED_DATABASE
    NSString* dbPath = [[NSBundle mainBundle] pathForResource: kDatabaseName ofType: @"couch"];
    NSAssert(dbPath, @"Couldn't find "kDatabaseName".couch");
    [gCouchbaseEmbeddedServer installDefaultDatabase: dbPath];
#endif
    if (![gCouchbaseEmbeddedServer start]) {
        [self showAlert: @"Couldn't start Couchbase."
                  error: gCouchbaseEmbeddedServer.error 
                  fatal: YES];
    }
#endif

    return YES;
}


-(void)couchbaseDidStart:(NSURL *)serverURL {
    NSLog(@"CouchDemo: couchbaseDidStart: <%@>", serverURL);
    if (serverURL == nil) {
        [self showAlert: @"Couldn't start Couchbase." 
                  error: gCouchbaseEmbeddedServer.error
                  fatal: YES];
        return;
    }

    CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
    self.database = [server databaseNamed: kDatabaseName];
    [server release];
    
#if !INSTALL_CANNED_DATABASE
    // Create the database on the first run of the app.
    if (![[self.database GET] wait])
        [[self.database create] wait];
#endif
    
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
