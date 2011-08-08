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
#import "DemoAppDelegate.h"

#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/RESTBody.h>
#import <Couchbase/CouchbaseEmbeddedServer.h>


@interface RootViewController ()
@property(nonatomic, retain)UIActivityIndicatorView *activity;
@property(nonatomic, retain)CouchDatabase *database;
@end


@implementation RootViewController


@synthesize dataSource;
@synthesize activity;
@synthesize database;
@synthesize tableView;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    [CouchUITableSource class];     // Prevents class from being dead-stripped by linker

    UIBarButtonItem* purgeButton = [[UIBarButtonItem alloc] initWithTitle: @"Purge"
                                                            style:UIBarButtonItemStylePlain
                                                           target: self 
                                                           action: @selector(purgeDeletedItems:)];
    self.navigationItem.leftBarButtonItem = [purgeButton autorelease];
    
    self.activity = [[[UIActivityIndicatorView alloc] 
                     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    [self.activity startAnimating];
    UIBarButtonItem* activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    activityButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = [activityButtonItem autorelease];
    
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [addItemBackground setFrame:CGRectMake(45, 8, 680, 44)];
        [addItemTextField setFrame:CGRectMake(56, 8, 665, 43)];
    }
}


- (void)dealloc {
    [database release];
    [super dealloc];
}


- (void)showErrorAlert: (NSString*)message forOperation: (RESTOperation*)op {
    NSLog(@"%@: op=%@, error=%@", message, op, op.error);
    [(DemoAppDelegate*)[[UIApplication sharedApplication] delegate] 
        showAlert: message error: op.error fatal: NO];
}


-(void)useDatabase:(CouchDatabase*)theDatabase {
    self.database = theDatabase;
    CouchLiveQuery* query = [[database getAllDocuments] asLiveQuery];
    query.descending = YES;  // Sort by descending ID, which will imply descending create time
    self.dataSource.query = query;
    self.dataSource.labelProperty = @"text";    // Document property to display in the cell label

    // Set up synchronization to/from a remote database:
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *syncpoint = [defaults objectForKey:@"syncpoint"];
    NSURL *remoteURL = [NSURL URLWithString:syncpoint];

    RESTOperation *pull = [database pullFromDatabaseAtURL: remoteURL
                                                  options: kCouchReplicationContinuous];
    [pull onCompletion:^() {
        if (pull.isSuccessful)
            NSLog(@"continous sync triggered from %@", syncpoint);
        else
            [self showErrorAlert: @"Unable to sync with the server. You may still work offline."
                  forOperation: pull];
	}];

    RESTOperation *push = [database pushToDatabaseAtURL: remoteURL
                                                options: kCouchReplicationContinuous];
    [push onCompletion:^() {
        if (push.isSuccessful)
            NSLog(@"continous sync triggered to %@", syncpoint);
        else
            [self showErrorAlert: @"Unable to sync with the server. You may still work offline." 
                  forOperation: pull];
	}];
}


#pragma mark -
#pragma mark Couch table source delegate


- (void)couchTableSource:(CouchUITableSource*)source
     willUpdateFromQuery:(CouchLiveQuery*)query
{
    // Turn off the activity indicator as soon as we get results on the initial load.
    [self.activity stopAnimating];
}


// Customize the appearance of table view cells.
- (void)couchTableSource:(CouchUITableSource*)source
             willUseCell:(UITableViewCell*)cell
                  forRow:(CouchQueryRow*)row
{
    // Set the cell background and font:
    static UIColor* kBGColor;
    if (!kBGColor)
        kBGColor = [[UIColor colorWithPatternImage: [UIImage imageNamed:@"item_background"]] 
                        retain];
    cell.backgroundColor = kBGColor;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    cell.textLabel.font = [UIFont fontWithName: @"Helvetica" size:18.0];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    // Configure the cell contents:
    NSDictionary* properties = row.document.properties;
    BOOL checked = [[properties valueForKey:@"check"] boolValue];
    
    UILabel *labelWithText = cell.textLabel;
    labelWithText.text = [properties valueForKey:@"text"];
    labelWithText.textColor = checked ? [UIColor grayColor] : [UIColor blackColor];

    [cell.imageView setImage:[UIImage imageNamed:
            (checked ? @"list_area___checkbox___checked" : @"list_area___checkbox___unchecked")]];
}


#pragma mark -
#pragma mark Table view delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CouchQueryRow *row = [self.dataSource rowAtIndex:indexPath.row];
    CouchDocument *doc = [row document];

    // Toggle the document's 'checked' property:
    NSMutableDictionary *docContent = [[doc.properties mutableCopy] autorelease];
    BOOL wasChecked = [[docContent valueForKey:@"check"] boolValue];
    [docContent setObject:[NSNumber numberWithBool:!wasChecked] forKey:@"check"];

    // Save changes, asynchronously:
    RESTOperation* op = [doc putProperties:docContent];
    [op onCompletion: ^{
        if (op.error)
            [self showErrorAlert: @"Failed to update item" forOperation: op];
        // Re-run the query:
		[self.dataSource.query start];
    }];
    [op start];
}


#pragma mark
#pragma mark Editing:


- (NSArray*)checkedDocuments {
    // If there were a whole lot of documents, this would be more efficient with a custom query.
    NSMutableArray* checked = [NSMutableArray array];
    for (CouchQueryRow* row in self.dataSource.rows) {
        CouchDocument* doc = row.document;
        if ([[doc.properties valueForKey:@"check"] boolValue])
            [checked addObject: doc];
    }
    return checked;
}


- (IBAction) purgeDeletedItems:(id)sender {
    NSUInteger numChecked = self.checkedDocuments.count;
    if (numChecked == 0)
        return;
    NSString* message = [NSString stringWithFormat: @"Are you sure you want to remove the %u"
                                                     " checked-off item%@?",
                                                     numChecked, (numChecked==1 ? @"" : @"s")];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Remove Completed Items?"
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle: @"Cancel"
                                          otherButtonTitles: @"Remove", nil];
    [alert show];
    [alert release];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)
        return;
    [dataSource deleteDocuments: self.checkedDocuments];
}


- (void)couchTableSource:(CouchUITableSource*)source
         operationFailed:(RESTOperation*)op
{
    NSString* message = op.isDELETE ? @"Couldn't delete item" : @"Operation failed";
    [self showErrorAlert: message forOperation: op];
}


#pragma mark -
#pragma mark UITextField delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___inactive.png"]];

	return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [addItemBackground setImage:[UIImage imageNamed:@"textfield___active.png"]];
}


-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Get the name of the item from the text field:
	NSString *text = addItemTextField.text;
    if (text.length == 0) {
        return;
    }
    [addItemTextField setText:nil];

    // Construct a unique document ID that will sort chronologically:
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *guid = (NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
	NSString *docId = [NSString stringWithFormat:@"%f-%@", CFAbsoluteTimeGetCurrent(), guid];
    [guid release];

    // Create the new document's properties:
	NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text"
                                , [NSNumber numberWithBool:NO], @"check"
                                , [[NSDate date] description], @"created_at"
                                , nil];

    // Save the document, asynchronously:
    CouchDocument* doc = [database documentWithID: docId];
    RESTOperation* op = [doc putProperties:inDocument];
    [op onCompletion: ^{
        if (op.error)
            [self showErrorAlert: @"Couldn't save the new item" forOperation: op];
        // Re-run the query:
		[self.dataSource.query start];
	}];
    [op start];
}


@end
