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

#define kDefaultSyncDbURL @"http://couchbase.iriscouch.com/grocery-sync"


@implementation DemoAppDelegate


@synthesize window;
@synthesize navigationController;


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

    // Show the splash screen for 2 seconds:
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 320, 460)];
        splashView.image = [UIImage imageNamed:@"Default.png"];
    }
    else
    {
        splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 768, 1004)];
        splashView.image = [UIImage imageNamed:@"Default~ipad.png"];
    }

	[self.window addSubview:splashView];
	[self performSelector:@selector(removeSplash) withObject:nil afterDelay:2];

    return YES;
}


-(void)removeSplash;
{
	[splashView removeFromSuperview];
	[splashView release];
    splashView = nil;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// CouchDB seems to get stuck when in background. exit() so we get relaunched freshly.
    // (Setting the UIApplicationExitsOnSuspend key in the Info.plist accomplishes the same goal.)

	exit(0);
}


- (void)dealloc {
	[splashView release];
	[navigationController release];
	[window release];
	[super dealloc];
}


@end
