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

#import "RootViewController.h"
#import "ConfigViewController.h"
#import "DemoAppDelegate.h"

#import <Couchbaselite/CouchbaseLite.h>


@interface RootViewController ()
@property(nonatomic, strong)CBLDatabase *database;
@property(nonatomic, strong)NSURL* remoteSyncURL;
- (void)updateSyncURL;
- (void)showSyncButton;
- (void)showSyncStatus;
- (IBAction)configureSync:(id)sender;
- (void)forgetSync;
@end


@implementation RootViewController


@synthesize dataSource;
@synthesize database;
@synthesize tableView;
@synthesize remoteSyncURL;


#pragma mark - View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc] initWithTitle: @"Clean"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(deleteCheckedItems:)];
    self.navigationItem.leftBarButtonItem = deleteButton;
    
    [self showSyncButton];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [addItemBackground setFrame:CGRectMake(45, 8, 680, 44)];
        [addItemTextField setFrame:CGRectMake(56, 8, 665, 43)];
    }

    // Create a query sorted by descending date, i.e. newest items first:
    NSAssert(database!=nil, @"Not hooked up to database yet");
    CBLLiveQuery* query = [[[database viewNamed:@"byDate"] createQuery] asLiveQuery];
    query.descending = YES;

    // Plug the query into the CBLUITableSource, which will use it to drive the table view.
    // (The CBLUITableSource uses KVO to observe the query's .rows property.)
    self.dataSource.query = query;
    self.dataSource.labelProperty = @"text";    // Document property to display in the cell label

    // Configure sync if necessary:
    [self updateSyncURL];
}


- (void)dealloc {
    [self forgetSync];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    // Check for changes after returning from the sync config view:
    [self updateSyncURL];
}


// Called at startup time by the app delegate to hook me up to the database.
- (void)useDatabase:(CBLDatabase*)theDatabase {
    self.database = theDatabase;

    // Define a view with a map function that indexes to-do items by creation date:
    [[theDatabase viewNamed: @"byDate"] setMapBlock: MAPBLOCK({
        id date = doc[@"created_at"];
        if (date)
            emit(date, doc);
    }) reduceBlock: nil version: @"1.1"];
    
    // and a validation function requiring parseable dates:
    [theDatabase setValidationNamed: @"created_at" asBlock: VALIDATIONBLOCK({
        if (newRevision.isDeletion)
            return;
        id date = (newRevision.properties)[@"created_at"];
        if (date && ! [CBLJSON dateWithJSONObject: date]) {
            [context rejectWithMessage: [@"invalid date " stringByAppendingString: [date description]]];
        }
    })];
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
    // Ask the CBLUITableSource for the corresponding query row, and get its document:
    CBLQueryRow *row = [self.dataSource rowAtIndex:indexPath.row];
    CBLDocument *doc = row.document;

    // Toggle the document's 'checked' property:
    NSMutableDictionary *docContent = [doc.properties mutableCopy];
    BOOL wasChecked = [docContent[@"check"] boolValue];
    docContent[@"check"] = @(!wasChecked);

    // Save changes:
    NSError* error;
    if (![doc putProperties: docContent error: &error]) {
        [self showErrorAlert: @"Failed to update item" forError: error];
    }
}


#pragma mark - Editing:


// Returns all the items that have been checked-off, as an array of CBLDocuments.
- (NSArray*)checkedDocuments {
    // (If there were a whole lot of documents, this would be more efficient with a custom query.)
    NSMutableArray* checked = [NSMutableArray array];
    for (CBLQueryRow* row in self.dataSource.rows) {
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
    NSString* message = [NSString stringWithFormat: @"Are you sure you want to remove the %u"
                                                     " checked-off item%@?",
                                                     numChecked, (numChecked==1 ? @"" : @"s")];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Remove Completed Items?"
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle: @"Cancel"
                                          otherButtonTitles: @"Remove", nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)
        return;
    NSError* error;
    // Tell the CBLUITableSource to delete the documents, instead of doing it directly.
    // This lets it tell the table-view the rows are going away, so the table display can animate.
    if (![dataSource deleteDocuments: self.checkedDocuments error: &error]) {
        [self showErrorAlert: @"Failed to delete items" forError: error];
    }
}

#pragma mark - UITextField delegate


// Highlight the text field when input begins.
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    addItemBackground.image = [UIImage imageNamed:@"textfield___active.png"];
}


// Un-highlight the text field when input ends.
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    addItemBackground.image = [UIImage imageNamed:@"textfield___inactive.png"];
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

    // Create the new document's properties:
	NSDictionary *document = @{@"text":       text,
                               @"check":      @NO,
                               @"created_at": [CBLJSON JSONObjectWithDate: [NSDate date]]};
    
    // Save the document:
    CBLDocument* doc = [database createDocument];
    NSError* error;
    if (![doc putProperties: document error: &error]) {
        [self showErrorAlert: @"Couldn't save new item" forError: error];
    }
}


#pragma mark - SYNC:


// Displays the sync configuration view.
- (IBAction)configureSync:(id)sender {
    UINavigationController* navController = (UINavigationController*)self.parentViewController;
    ConfigViewController* controller = [[ConfigViewController alloc] init];
    [navController pushViewController: controller animated: YES];
}


// Updates the database's sync URL from the saved pref.
- (void)updateSyncURL {
    if (!self.database)
        return;
    NSURL* newRemoteURL = nil;
    NSString *pref = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncpoint"];
    if (pref.length > 0)
        newRemoteURL = [NSURL URLWithString: pref];

    [self forgetSync];

    // Tell the database to use this URL for bidirectional sync.
    // This call returns an array of the pull and push replication objects:
    NSArray* repls = [self.database replicationsWithURL: newRemoteURL exclusively: YES];
    if (repls) {
        _pull = repls[0];
        _push = repls[1];
        _pull.continuous = _push.continuous = YES;
        // Observe replication progress changes, in both directions:
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(replicationProgress:)
                     name: kCBLReplicationChangeNotification object: _pull];
        [nctr addObserver: self selector: @selector(replicationProgress:)
                     name: kCBLReplicationChangeNotification object: _push];
        [_push start];
        [_pull start];
    }
}


// Stops observing the current push/pull replications, if any.
- (void) forgetSync {
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    if (_pull) {
        [nctr removeObserver: self name: nil object: _pull];
        _pull = nil;
    }
    if (_push) {
        [nctr removeObserver: self name: nil object: _push];
        _push = nil;
    }
}


// When replication is idle (or not configured), show a "Sync" button to configure it.
- (void)showSyncButton {
    if (!showingSyncButton) {
        showingSyncButton = YES;
        UIBarButtonItem* syncButton =
                [[UIBarButtonItem alloc] initWithTitle:@"Configure"
                                                 style:UIBarButtonItemStylePlain
                                                target:self
                                                action:@selector(configureSync:)];
        self.navigationItem.rightBarButtonItem = syncButton;
    }
}


// When replication is active, show a progress bar.
- (void)showSyncStatus {
    if (showingSyncButton) {
        showingSyncButton = NO;
        if (!progress) {
            progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            CGRect frame = progress.frame;
            frame.size.width = self.view.frame.size.width / 4.0f;
            progress.frame = frame;
        }
        UIBarButtonItem* progressItem = [[UIBarButtonItem alloc] initWithCustomView:progress];
        progressItem.enabled = NO;
        self.navigationItem.rightBarButtonItem = progressItem;
    }
}


// Called in response to replication-change notifications. Updates the progress UI.
- (void) replicationProgress: (NSNotificationCenter*)n {
    if (_pull.status == kCBLReplicationActive || _push.status == kCBLReplicationActive) {
        // Sync is active -- aggregate the progress of both replications and compute a fraction:
        unsigned completed = _pull.completedChangesCount + _push.completedChangesCount;
        unsigned total = _pull.changesCount+ _push.changesCount;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        [self showSyncStatus];
        // Update the progress bar, avoiding divide-by-zero exceptions:
        progress.progress = (completed / (float)MAX(total, 1u));
    } else {
        // Sync is idle -- hide the progress bar and show the config button:
        [self showSyncButton];
    }

    // Check for any change in error status and display new errors:
    NSError* error = _pull.lastError ? _pull.lastError : _push.lastError;
    if (error != _syncError) {
        _syncError = error;
        if (error)
            [self showErrorAlert: @"Error syncing" forError: error];
    }
}


@end
