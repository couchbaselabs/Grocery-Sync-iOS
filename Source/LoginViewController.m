//
//  LoginViewController.m
//  GrocerySync
//
//  Created by Pasin Suriyentrakorn on 6/15/16.
//
//

#import "LoginViewController.h"
#import <GoogleSignIn/GoogleSignIn.h>

#define kGoogleClientID @"31919031332-sjiopc9dnh217somhc94b3s1kt7oe2mu.apps.googleusercontent.com"

@interface LoginViewController () <GIDSignInDelegate, GIDSignInUIDelegate>

@property (weak, nonatomic) IBOutlet GIDSignInButton *gIDSignInButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GIDSignIn *signIn = [GIDSignIn sharedInstance];
    signIn.shouldFetchBasicProfile = YES;
    signIn.delegate = self;
    signIn.uiDelegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation
- (void)start {
    [self performSegueWithIdentifier:@"start" sender:self];
}

#pragma mark - Application Level Setup

+ (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GIDSignIn sharedInstance].clientID = kGoogleClientID;
    return YES;
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

+ (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

#pragma mark - Login / Logout

- (void)logout {
    [[GIDSignIn sharedInstance] signOut];
    [[GIDSignIn sharedInstance] disconnect];
    if ([self.delegate respondsToSelector:@selector(didLogout:)])
        [self.delegate didLogout:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Auth Code Flow

- (IBAction)authCodeFlowButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didAuthCodeSignIn:)])
        [self.delegate didAuthCodeSignIn:self];
}


#pragma mark - GIDSignInDelegate

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(didGoogleSignIn:withIdToken:withError:)]) {
        NSString *idToken = user.authentication.idToken;
        [self.delegate didGoogleSignIn:self withIdToken:idToken withError:error];
    }
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    NSLog(@"Google SignIn : User disconnected.");
}

@end
