//
//  CouchTableViewController.m
//  CouchDemo
//
//  Created by Jens Alfke on 8/2/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import "CouchTableViewController.h"
#import <CouchCocoa/CouchCocoa.h>


@implementation CouchTableViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)dealloc {
    [_rows release];
    [_query removeObserver: self forKeyPath: @"rows"];
    [_query release];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


#pragma mark -
#pragma mark ROW ACCESSORS:


@synthesize rows;


- (CouchQueryRow*) rowAtIndex: (NSUInteger)index {
    return [_rows objectAtIndex: index];
}


#pragma mark -
#pragma mark QUERY HANDLING:


- (CouchQuery*) query {
    return _query;
}

- (void) setQuery:(CouchQuery *)query {
    if (query != _query) {
        [_query removeObserver: self forKeyPath: @"rows"];
        [_query release];
        _query = [[query asLiveQuery] retain];
        [_query addObserver: self forKeyPath: @"rows" options: 0 context: NULL];
        [self reloadFromQuery];
    }
}


-(void) reloadFromQuery {
    CouchQueryEnumerator* rowEnum = _query.rows;
    if (rowEnum) {
        [_rows release];
        _rows = [rowEnum.allObjects mutableCopy];
        [self.tableView reloadData];
    }
}


- (void) observeValueForKeyPath: (NSString*)keyPath ofObject: (id)object
                         change: (NSDictionary*)change context: (void*)context 
{
    if (object == _query)
        [self reloadFromQuery];
}


#pragma mark -
#pragma mark Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _rows.count;
}


- (void)tableView:(UITableView *)tableView
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
         forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the document from the database, asynchronously.
        RESTOperation* op = [[[self rowAtIndex:indexPath.row] document] DELETE];
        [op onCompletion: ^{
            if (!op.isSuccessful) {
                // If the delete failed, undo the table row deletion by reloading from the db:
                [self deletionFailed: op];
                [self reloadFromQuery];
            }
        }];
        [op start];
        
        // Delete the row from the table data source.
        [_rows removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (void)deletionFailed: (RESTOperation*)op {
    NSLog(@"CouchTableViewController: Deletion failed: %@", op);
}


@end
