//
//  RootViewController.m
//  Grocery Sync
//
//  Created by Jan Lehnardt on 27/11/2010.
//  Copyright 2011-2013 Couchbase, Inc.
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

// NOTE: This file contains "pragma mark" markers highlighting the Couchbase Lite
// operations. You can easily find these by pulling down the Xcode methods menu above.

#import "RootViewController.h"
#import "DemoAppDelegate.h"

#import <Couchbaselite/CouchbaseLite.h>


@implementation RootViewController
{
    CBLDatabase *database;
    
    IBOutlet UITableView *tableView;
    IBOutlet CBLUITableSource* dataSource;
    IBOutlet UITextField *addItemTextField;
}


#pragma mark - View lifecycle


// Called at startup time by the app delegate to hook me up to the database.
- (void)useDatabase:(CBLDatabase*)theDatabase {
    database = theDatabase;

    // Define a view with a map function that indexes to-do items by creation date:
#pragma mark Define view
    [[theDatabase viewNamed: @"byDate"] setMapBlock: MAPBLOCK({
        id date = doc[@"created_at"];
        if (date)
            emit(date, doc);
    }) reduceBlock: nil version: @"1.1"];
    
    // and a validation function requiring parseable dates:
#pragma mark Define validation
    [theDatabase setValidationNamed: @"created_at" asBlock: VALIDATIONBLOCK({
        if (newRevision.isDeletion)
            return;
        id date = (newRevision.properties)[@"created_at"];
        if (date && ! [CBLJSON dateWithJSONObject: date]) {
            [context rejectWithMessage: [@"invalid date " stringByAppendingString: [date description]]];
        }
    })];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    DemoAppDelegate* app = (DemoAppDelegate*)[[UIApplication sharedApplication] delegate];
    [self useDatabase:app.database];
    
    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc] initWithTitle: @"Clean"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(deleteCheckedItems:)];
    self.navigationItem.leftBarButtonItem = deleteButton;

    tableView.backgroundView = nil;
    tableView.backgroundColor = [UIColor clearColor];
    
    if (database) {
#pragma mark Create database query
        // Create a query sorted by descending date, i.e. newest items first:
        CBLLiveQuery* query = [[[database viewNamed:@"byDate"] createQuery] asLiveQuery];
        query.descending = YES;

        // Plug the query into the CBLUITableSource, which will use it to drive the table view.
        // (The CBLUITableSource uses KVO to observe the query's .rows property.)
#pragma mark Configure table view for query
        dataSource.query = query;
        dataSource.labelProperty = @"text";    // Document property to display in the cell label
    }
}


- (void)showErrorAlert: (NSString*)message forError: (NSError*)error {
    DemoAppDelegate* delegate = (DemoAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showAlert: message error: error fatal: NO];
}


#pragma mark - CBLUITableSource delegate


// Customize the appearance of table view cells.
- (void)couchTableSource:(CBLUITableSource*)source
             willUseCell:(UITableViewCell*)cell
                  forRow:(CBLQueryRow*)row
{
    // Set the cell background and font:
    static UIColor* kBGColor;
    if (!kBGColor)
        kBGColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"item_background"]];
    cell.backgroundColor = kBGColor;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    cell.textLabel.font = [UIFont fontWithName: @"Helvetica" size:18.0];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    // Configure the cell contents. Our view's map function (above) copies the document properties
    // into its value, so we can read them from there without having to load the document.
#pragma mark Set checkbox state from document
    NSDictionary* rowValue = row.value;
    BOOL checked = [rowValue[@"check"] boolValue];
    if (checked) {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.imageView.image = [UIImage imageNamed:@"list_area___checkbox___checked"];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.imageView.image = [UIImage imageNamed: @"list_area___checkbox___unchecked"];
    }
    // cell.textLabel.text is already set, thanks to setting up labelProperty above.
}


#pragma mark - Table view delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma mark Toggle checked state
    // Ask the CBLUITableSource for the corresponding query row, and get its document:
    CBLQueryRow *row = [dataSource rowAtIndex:indexPath.row];
    CBLDocument *doc = row.document;

    NSError* error;
    CBLSavedRevision* newRev = [doc update:^BOOL(CBLUnsavedRevision *rev) {
        // Toggle the "check" property of the new revision to be saved:
        BOOL wasChecked = [rev[@"check"] boolValue];
        rev[@"check"] = @(!wasChecked);
        return YES;
    } error: &error];

    if (!newRev) {
        [self showErrorAlert: @"Failed to update item" forError: error];
    }
}


#pragma mark - Editing:


// Returns all the items that have been checked-off, as an array of CBLDocuments.
- (NSArray*)checkedDocuments {
#pragma mark Find all checked docs
    // (If there were a whole lot of documents, this would be more efficient with a custom query.)
    NSMutableArray* checked = [NSMutableArray array];
    for (CBLQueryRow* row in dataSource.rows) {
        CBLDocument* doc = row.document;
        if ([doc[@"check"] boolValue])       // you can get properties with [], as in NSDictionaries
            [checked addObject: doc];
    }
    return checked;
}


// Invoked by the "Clean Up" button.
- (IBAction)deleteCheckedItems:(id)sender {
    NSUInteger numChecked = self.checkedDocuments.count;
    if (numChecked == 0)
        return;
    NSString* message = [NSString stringWithFormat: @"Are you sure you want to remove the %lu"
                                                     " checked-off item%@?",
                                                     (unsigned long)numChecked,
                                                     (numChecked==1 ? @"" : @"s")];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Remove Completed Items?"
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle: @"Cancel"
                                          otherButtonTitles: @"Remove", nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return; // canceled
    }
    NSError* error;
    // Tell the CBLUITableSource to delete the documents, instead of doing it directly.
    // This lets it tell the table-view the rows are going away, so the table display can animate.
#pragma mark Delete checked docs
    if (![dataSource deleteDocuments: self.checkedDocuments error: &error]) {
        [self showErrorAlert: @"Failed to delete items" forError: error];
    }
}

#pragma mark - UITextField delegate


// Highlight the text field when input begins.
- (void)textFieldDidBeginEditing:(UITextField *)textField {

}

// Un-highlight the text field when input ends.
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}


// Add a new item when text input ends.
-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Get the name of the item from the text field:
	NSString *text = addItemTextField.text;
    if (text.length == 0) {
        return;
    }
    addItemTextField.text = nil;

#pragma mark Create a new document
    DemoAppDelegate* app = (DemoAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *username = app.username;

    // Create the new document's properties:
	NSDictionary *document = @{@"text":       text,
                               @"check":      @NO,
                               @"owner":      username,
                               @"created_at": [CBLJSON JSONObjectWithDate: [NSDate date]]};
    
    // Save the document:
    CBLDocument* doc = [database createDocument];
    NSError* error;
    if (![doc putProperties: document error: &error]) {
        [self showErrorAlert: @"Couldn't save new item" forError: error];
    }
}

@end
