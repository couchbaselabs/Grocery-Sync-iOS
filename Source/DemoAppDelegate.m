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
#import <Couchbase/CouchbaseMobile.h>
#import <CouchCocoa/CouchCocoa.h>

// The name of the database the app will use.
#define kDatabaseName @"grocery-sync"

// The default remote database URL to sync with, if the user hasn't set a different one as a pref.
//#define kDefaultSyncDbURL @"http://couchbase.iriscouch.com/grocery-sync"

// Set this to 1 to install a pre-built database from a ".couch" resource file on first run.
#define INSTALL_CANNED_DATABASE 0

// Define this to use a server at a specific URL, instead of the embedded Couchbase Mobile.
// This can be useful for debugging, since you can use the admin console (futon) to inspect
// or modify the database contents.
//#define USE_REMOTE_SERVER @"http://localhost:5984/"


@interface DemoAppDelegate ()
- (void)showSplash;
- (void)removeSplash;
@end


@implementation DemoAppDelegate


@synthesize window;
@synthesize navigationController;
@synthesize database;


// Override point for customization after application launch.
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"------ application:didFinishLaunchingWithOptions:");
#ifdef kDefaultSyncDbURL
    // Register the default value of the pref for the remote database URL to sync with:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appdefaults = [NSDictionary dictionaryWithObject:kDefaultSyncDbURL
                                                            forKey:@"syncpoint"];
    [defaults registerDefaults:appdefaults];
    [defaults synchronize];
#endif
    
    // Add the navigation controller's view to the window and display.
	[window addSubview:navigationController.view];
	[window makeKeyAndVisible];
    
    [self showSplash];

    // Start the Couchbase Mobile server:
    // gCouchLogLevel = 1;
    [CouchbaseMobile class];  // prevents dead-stripping
    CouchEmbeddedServer* server;
#ifdef USE_REMOTE_SERVER
    server = [[CouchEmbeddedServer alloc] initWithURL: [NSURL URLWithString: USE_REMOTE_SERVER]];
#else
    server = [[CouchEmbeddedServer alloc] init];
#endif
    
#if INSTALL_CANNED_DATABASE
    NSString* dbPath = [[NSBundle mainBundle] pathForResource: kDatabaseName ofType: @"couch"];
    NSAssert(dbPath, @"Couldn't find "kDatabaseName".couch");
    [server installDefaultDatabase: dbPath];
#endif
    
    [server start: ^{  // ... this block runs later on when the server has started up:
        if (server.error) {
            [self showAlert: @"Couldn't start Couchbase." error: server.error fatal: YES];
            return;
        }
        
        self.database = [server databaseNamed: kDatabaseName];
        
#if !INSTALL_CANNED_DATABASE && !defined(USE_REMOTE_SERVER)
        // Create the database on the first run of the app.
        NSError* error;
        if (![self.database ensureCreated: &error]) {
            [self showAlert: @"Couldn't create local database." error: error fatal: YES];
            return;
        }
#endif
        
        database.tracksChanges = YES;
        
        // Tell the RootViewController:
        RootViewController* root = (RootViewController*)navigationController.topViewController;
        [root useDatabase: database];
        
        [self removeSplash];
    }];
    return YES;
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
        message = [NSString stringWithFormat: @"%@\n\n%@", message, error.localizedDescription];
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: (fatal ? @"Fatal Error" : @"Error")
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
