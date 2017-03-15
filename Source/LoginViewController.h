//
//  LoginViewController.h
//  GrocerySync
//
//  Created by Pasin Suriyentrakorn on 6/15/16.
//
//

#import <UIKit/UIKit.h>

@protocol LoginViewControllerDelegate;

@interface LoginViewController : UIViewController

@property id<LoginViewControllerDelegate> delegate;

+ (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

+ (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options;

- (void)start;
- (void)logout;

@end

@protocol LoginViewControllerDelegate <NSObject>
- (void)didLogout:(LoginViewController *)controller;
- (void)didAuthCodeSignIn:(LoginViewController *)controller;
- (void)didGoogleSignIn:(LoginViewController *)controller withIdToken:(NSString *)idToken withError:(NSError *)error;
@end

