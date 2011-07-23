//
//  NewServerController.h
//  CouchDemo
//
//  Created by Arvind on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Server;
extern NSString *servername;

@interface NewServerController : UIViewController {
	UITextView *textView;
    NSMutableArray *items;
	id delegate;
    Server *userserver;
    //NSString *servername;
}

@property(nonatomic,retain)IBOutlet	UITextView *textView;
@property(assign) id delegate;
@property(nonatomic, retain)NSURL *couchbaseURL;
@property(nonatomic, retain)NSMutableArray *items;
@property(nonatomic, retain)Server *userserver;
//@property(nonatomic, retain) NSString *servername;


-(void)loadItemsIntoView;
-(NSURL *)getCouchbaseURL;

@end

