//
//  RootViewController.m
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

#import "RootViewController.h"
#import "NewServerController.h"
#import "CCouchDBServer.h"
#import "CCouchDBDatabase.h"
#import "NewItemViewController.h"
#import "DatabaseManager.h"
#import "CouchDBClientTypes.h"
#import "CURLOperation.h"





@implementation RootViewController
@synthesize items;
@synthesize checked;
@synthesize syncItem;
@synthesize activityButtonItem;
@synthesize couchbaseURL;
@synthesize delegate;

//NSMutableArray * checked = [NSMutableArray arrayWithObjects: @"",nil ];

#pragma mark -
#pragma mark View lifecycle

-(NSURL *)getCouchbaseURL {
	return self.couchbaseURL;
}



-(void)couchbaseDidStart:(NSURL *)serverURL {
	self.couchbaseURL = serverURL;
	[self loadItemsIntoView];
	NSLog(@"serverURL %@",serverURL);
	self.syncItem = [[[UIBarButtonItem alloc] 
					  initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered
					  target:self 
					  action:@selector(sync) 
					  ] autorelease];
	self.navigationItem.rightBarButtonItem = self.syncItem;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
    
    //_checkboxSelections =0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    UIBarButtonItem* addItem = [[UIBarButtonItem alloc]
                           initWithTitle:@"New Item" style:UIBarButtonItemStyleBordered target:self action:@selector(addItem)];
    self.navigationItem.leftBarButtonItem = addItem;
    [addItem release];

    
	UIActivityIndicatorView *activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	[activity startAnimating];
	self.activityButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activity] autorelease];
	self.activityButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem = activityButtonItem;
}

-(void)sync
{
	self.syncItem = self.navigationItem.rightBarButtonItem;
	[self.navigationItem setRightBarButtonItem: self.activityButtonItem animated:YES];

	DatabaseManager *manager = [DatabaseManager sharedManager:self.couchbaseURL];
	DatabaseManagerSuccessHandler successHandler = ^() {
  	    //woot	
		NSLog(@"success handler called!");
		[self loadItemsIntoView];
	};
    
	DatabaseManagerErrorHandler errorHandler = ^(id error) {
		// doh	
	};
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [defaults objectForKey:@"servername"];

    
	[manager syncFrom:name to:@"demo" onSuccess:successHandler onError:errorHandler];
    [manager syncFrom:@"demo" to:name onSuccess:^() {} onError:^(id error) {}];
}

-(void)loadItemsIntoView
{
	if(self.navigationItem.rightBarButtonItem != syncItem) {
		[self.navigationItem setRightBarButtonItem: syncItem animated:YES];
	}
    
	DatabaseManager *sharedManager = [DatabaseManager sharedManager:self.couchbaseURL];
	CouchDBSuccessHandler inSuccessHandler = ^(id inParameter) {
        //		NSLog(@"RVC Wooohooo! %@: %@", [inParameter class], inParameter);
		self.items = inParameter;
        NSLog(@"%@",self.items);
        
		[self.tableView reloadData];
	};
	
	CouchDBFailureHandler inFailureHandler = ^(NSError *error) {
		NSLog(@"RVC D'OH! %@", error);
	};
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"true", @"descending", @"true", @"include_docs", nil];
	CURLOperation *op = [sharedManager.database operationToFetchAllDocumentsWithOptions:options 
																	 withSuccessHandler:inSuccessHandler 
																		 failureHandler:inFailureHandler];
	[op start];
}	


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
	// Configure the cell.
	CCouchDBDocument *doc = [self.items objectAtIndex:indexPath.row];
    id check = [NSNumber numberWithInteger: 1];
    
    if ([[doc valueForKey:@"content"] valueForKey:@"check"] == check) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSLog(@"CHECK");
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSLog(@"NONE");
    }
    cell.textLabel.text = [[doc valueForKey:@"content"] valueForKey:@"text"];

    return cell;
    
}

-(void)newItemAdded
{
	[self loadItemsIntoView];
	[self dismissModalViewControllerAnimated:YES];
}


-(void)addItem
{
	// TBD
	NewItemViewController *newItemVC = [[NewItemViewController alloc] initWithNibName:@"NewItemViewController" bundle:nil];
	newItemVC.delegate = self;
	UINavigationController *newItemNC = [[UINavigationController alloc] initWithRootViewController:newItemVC];
	[self presentModalViewController:newItemNC animated:YES];
	[newItemVC release];
	[newItemNC release];
}



#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
		NSUInteger position = [indexPath indexAtPosition:1]; // indexPath is [0, idx]
		[[DatabaseManager sharedManager:self.couchbaseURL] deleteDocument: [items objectAtIndex:position]];
		[items removeObjectAtIndex: position];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //arvind - toggle the indexpath.row bit, to have the ability to check / uncheck
//	_checkboxSelections ^= (1 << indexPath.row);
    CCouchDBDocument *doc = [self.items objectAtIndex:indexPath.row];
   // NSLog([doc description]);
    
    NSMutableDictionary *docContent = [[NSMutableDictionary alloc] init];//[doc valueForKey:@"content"];
    [docContent addEntriesFromDictionary:[doc valueForKey:@"content"]];
    id zero = [NSNumber numberWithInteger: 0];
    id one = [NSNumber numberWithInteger: 1];
    
    if ([docContent valueForKey:@"check"] == one) {
        [docContent setObject:zero forKey:@"check"];
    }
    else{
        [docContent setObject:one forKey:@"check"];
    
    }
    //create a document of the dictionary and replace the old document
    [doc populateWithJSON:docContent];
    
    DatabaseManager *sharedManager = [DatabaseManager sharedManager:self.couchbaseURL];
	CouchDBSuccessHandler inSuccessHandler = ^(id inParameter) {
        [self loadItemsIntoView];

	};
	
	CouchDBFailureHandler inFailureHandler = ^(NSError *error) {
		NSLog(@"RVC D'OH! %@", error);
	};

    
    CURLOperation *up = [sharedManager.database operationToUpdateDocument:doc successHandler:inSuccessHandler failureHandler:inFailureHandler];
    
    [up start];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [items release];
    [checked release];
    [super dealloc];
}


@end

