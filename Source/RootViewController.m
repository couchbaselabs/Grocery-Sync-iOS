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
#import <CouchCocoa/CouchCocoa.h>
#import <Couchbase/CouchbaseEmbeddedServer.h>

@implementation RootViewController
@synthesize items;
@synthesize activityButtonItem;
@synthesize activity;
@synthesize database;
@synthesize tableView;

#pragma mark -
#pragma mark View lifecycle

-(CouchDatabase *) getDatabase {
	return database;
}



-(void)couchbaseDidStart:(NSURL *)serverURL {
    CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
    // uncomment the next line to run with Couchbase Single on your local workstation
//    CouchServer *server = [[CouchServer alloc] init];
    self.database = [[server databaseNamed: @"grocery-sync"] retain];
    self.database.tracksChanges = YES;

    [server release];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(databaseChanged:)
                                                 name: kCouchDatabaseChangeNotification 
                                               object: database];
    
    [self loadItemsIntoView];
    [self setupSync];
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void) databaseChanged: (NSNotification*)n {
    // Wait to redraw the table, else there is a race condition where if the
    // DemoItem gets notified after I do, it won't have updated timeSinceExternallyChanged yet.
    [self performSelector: @selector(loadItemsDueToChanges) withObject: nil afterDelay:0.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // start the Couchbase Server
    NSString* dbPath = [[NSBundle mainBundle] pathForResource: @"grocery-sync" ofType: @"couch"];
    NSAssert(dbPath, @"Couldn't find grocery-sync.couch");

    CouchbaseEmbeddedServer* cb = [[CouchbaseEmbeddedServer alloc] init];
    cb.delegate = self;
    [cb installDefaultDatabase: dbPath];
    if (![cb start]) {
        NSLog(@"OMG: Couchbase couldn't start! Exiting! Error = %@", cb.error);
        exit(1);    // Panic!
    }
    
    self.activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    [self.activity startAnimating];
    self.activityButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activity] autorelease];
    self.activityButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = activityButtonItem;

    [self.tableView setBackgroundColor:[UIColor clearColor]];
}

-(void)setupSync
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *syncpoint = [defaults objectForKey:@"syncpoint"];
    NSURL *remoteURL = [NSURL URLWithString:syncpoint];
    RESTOperation *pull = [database pullFromDatabaseAtURL: remoteURL options: kCouchReplicationContinuous];
    [pull onCompletion:^() {
        NSLog(@"continous sync triggered from %@", syncpoint);
	}];
    RESTOperation *push = [database pushToDatabaseAtURL: remoteURL options: kCouchReplicationContinuous];
    [push onCompletion:^() {
        NSLog(@"continous sync triggered to %@", syncpoint);
	}];
}

-(void)loadItemsDueToChanges {
    NSLog(@"loadItemsDueToChanges");
    [self refreshItems];
    [self.tableView reloadData];
}

-(void)loadItemsIntoView {
    [self refreshItems];
    [self.tableView reloadData];
}

-(void) refreshItems {
    [self.activity startAnimating];
    CouchQuery *allDocs = [database getAllDocuments];
    allDocs.descending = YES;
    self.items = allDocs.rows;
    [self.activity stopAnimating];
}


-(void)newItemAdded {
	[self loadItemsIntoView];
}



#pragma mark -
#pragma mark Table view data source

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 52;
//}

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
    UITableViewCell *cell;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ListItem" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];

        if (indexPath.row == 0) {
            UIImageView *backgroundImage = (UIImageView*)[cell viewWithTag:1];
            [backgroundImage setImage:[UIImage imageNamed:@"top.png"]];
        }
        if (indexPath.row == [self.items count]-1) {
            UIImageView *backgroundImage = (UIImageView*)[cell viewWithTag:1];
            [backgroundImage setImage:[UIImage imageNamed:@"bottom.png"]];

            UIImageView *line_doted = (UIImageView*)[cell viewWithTag:4];
            [line_doted setAlpha:0];
        }
    }
    
    // Configure the cell.
    CouchQueryRow *row = [self.items rowAtIndex:indexPath.row];
    UIImageView *checkBoxImageView = (UIImageView*)[cell viewWithTag:3];

    if ([row.documentProperties valueForKey:@"check"] == [NSNumber numberWithBool:YES]) {
        [checkBoxImageView setImage:[UIImage imageNamed:@"list_area___checkbox___checked"]];
        [checkBoxImageView setFrame:CGRectMake(13, 10, 32, 29)];
    } else {
        [checkBoxImageView setImage:[UIImage imageNamed:@"list_area___checkbox___unchecked"]];
        [checkBoxImageView setFrame:CGRectMake(13, 14, 24, 25)];
    };
    UILabel *labelWIthText = (UILabel*)[cell viewWithTag:2];
    labelWIthText.text = [row.documentProperties valueForKey:@"text"];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        RESTOperation* op = [[[items rowAtIndex:indexPath.row] document] DELETE];
        [op onCompletion: ^{
            [self refreshItems]; // BLOCKING
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    [docContent addEntriesFromDictionary:row.documentProperties];
    id jsonFalse = [NSNumber numberWithBool:NO];
    id jsonTrue = [NSNumber numberWithBool:YES];
    
    if ([docContent valueForKey:@"check"] == jsonTrue) {
        [docContent setObject:jsonFalse forKey:@"check"];
    }
    else{
        [docContent setObject:jsonTrue forKey:@"check"];
    
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
    [docContent release];
}

- (void)dealloc {
    [items release];
    [database release];
    [super dealloc];
}

#pragma mark -
#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___inactive.png"]];

	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___active.png"]];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([addItemTextField.text length] == 0) {
        return;
    }

    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *guid = (NSString*)CFUUIDCreateString(nil, uuid);

    CFRelease(uuid);

	NSString *docId = [NSString stringWithFormat:@"%f-%@", CFAbsoluteTimeGetCurrent(), guid];

    [guid release];

	NSString *text = addItemTextField.text;

	NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text"
                                , [NSNumber numberWithBool:NO], @"check"
                                , [[NSDate date] description], @"created_at"
                                , nil];

    CouchDocument* doc = [[self getDatabase] documentWithID: docId];
    RESTOperation* op = [doc putProperties:inDocument];
    [op onCompletion: ^{
        if (op.error) {
            NSLog(@"error saving doc %@", [op.error description]);
        }
		NSLog(@"saved doc! %@", [op description]);
		[self performSelector:@selector(newItemAdded)];
	}];
    [op start];

    [addItemTextField setText:nil];
}


@end

