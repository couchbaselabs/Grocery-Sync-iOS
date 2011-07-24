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
#import "NewItemViewController.h"
#import <Couch/Couch.h>

@implementation RootViewController
@synthesize items;
@synthesize syncItem;
@synthesize activityButtonItem;
@synthesize database;

#pragma mark -
#pragma mark View lifecycle

-(CouchDatabase *) getDatabase {
	return database;
}



-(void)couchbaseDidStart:(NSURL *)serverURL {
    CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
    self.database = [[server databaseNamed: @"demo"] retain];
    [server release];
    
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [defaults objectForKey:@"servername"];
    NSURL *remoteURL = [NSURL URLWithString:name];
    RESTOperation *pull = [database pullFromDatabaseAtURL: remoteURL options: 0];
    [pull onCompletion:^() {
		NSLog(@"pulled");
		[self loadItemsIntoView];
	}];
    RESTOperation *push = [database pushToDatabaseAtURL: remoteURL options: 0];
    [push onCompletion:^() {
		NSLog(@"pushed");
	}];
    [pull start];
    [push start];
}

-(void)loadItemsIntoView
{
	if(self.navigationItem.rightBarButtonItem != syncItem) {
		[self.navigationItem setRightBarButtonItem: syncItem animated:YES];
	}
    [self refreshItems];
    [self.tableView reloadData];
}

-(void) refreshItems {
    CouchQuery *allDocs = [database getAllDocuments];
    allDocs.descending = YES;
    self.items = allDocs.rows;
}




-(void)newItemAdded
{
	[self loadItemsIntoView];
	[self dismissModalViewControllerAnimated:YES];
}


-(void)addItem
{
    NewItemViewController *newItemVC = [[NewItemViewController alloc] initWithNibName:@"NewItemViewController" bundle:nil];
    newItemVC.delegate = self;
    UINavigationController *newItemNC = [[UINavigationController alloc] initWithRootViewController:newItemVC];
    [self presentModalViewController:newItemNC animated:YES];
    [newItemVC release];
    [newItemNC release];
}

// - (BOOL)textFieldShouldReturn:(UITextField *)textField { 
//     //[textField resignFirstResponder];  
//     CFUUIDRef uuid = CFUUIDCreate(nil);
//     NSString *guid = (NSString*)CFUUIDCreateString(nil, uuid);
//     CFRelease(uuid);
//     NSString *docId = [NSString stringWithFormat:@"%f-%@", CFAbsoluteTimeGetCurrent(), guid];
//     [guid release];
//     
//     NSString *text = textField.text;
//      
//  NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text"
//                                 , [[NSDate date] description], @"created_at"
//                                 , [NSNumber numberWithInt:0],@"check", nil];
//     CouchDocument* doc = [database documentWithID: docId];
//     RESTOperation* op = [doc putProperties:inDocument];
//     [op onCompletion: ^{
//         if (op.error) {
//             NSLog(@"error saving doc %@", [op.error description]);
//         }
//         NSLog(@"saved doc! %@", [op description]);
//         [self newItemAdded];
//     }];
//     [op start];
//       
//     return YES; 
// }


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
	CouchQueryRow *row = [self.items rowAtIndex:indexPath.row];
    if ([row.documentContents valueForKey:@"check"] == [NSNumber numberWithInteger: 1]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
	cell.textLabel.text = [row.documentContents valueForKey:@"text"];
    return cell;
}


// Override to support conditional editing of the table view.
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    // Return NO if you do not want the specified item to be editable.
//    return YES;
//}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        RESTOperation* op = [[[items rowAtIndex:indexPath.row] document] DELETE];
        [op onCompletion: ^{
            [self refreshItems]; // BLOCKING
            // TODO return to the smooth style of deletion (eg animate the delete before the server responds...)
            //		[items removeRowAtIndex: position];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
        [op start];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CouchQueryRow *row = [self.items rowAtIndex:indexPath.row];
    CouchDocument *doc = [row document];
    NSMutableDictionary *docContent = [[NSMutableDictionary alloc] init];//[doc valueForKey:@"content"];
    [docContent addEntriesFromDictionary:row.documentContents];
    id zero = [NSNumber numberWithInteger: 0];
    id one = [NSNumber numberWithInteger: 1];
    
    if ([docContent valueForKey:@"check"] == one) {
        [docContent setObject:zero forKey:@"check"];
    }
    else{
        [docContent setObject:one forKey:@"check"];
    
    }
    //create a document of the dictionary and replace the old document
    RESTOperation* op = [doc putProperties:docContent];
    [op onCompletion: ^{
        if (op.error) {
            NSLog(@"error updating doc %@", [op.error description]);
        }
        NSLog(@"updated doc! %@", [op description]);
        [self loadItemsIntoView];
    }];
    [op start];
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
    [database release];
    [super dealloc];
}


@end

