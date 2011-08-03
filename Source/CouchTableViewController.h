//
//  CouchTableViewController.h
//  CouchDemo
//
//  Created by Jens Alfke on 8/2/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CouchQuery, CouchQueryRow, RESTOperation;

/** A UITableViewController driven by a CouchbaseQuery (i.e. a CouchDB 'view'). */
@interface CouchTableViewController : UITableViewController
{
    @private
    CouchQuery* _query;
	NSMutableArray* _rows;
}

@property (retain) CouchQuery* query;

-(void) reloadFromQuery;

@property (readonly) NSArray* rows;
- (CouchQueryRow*) rowAtIndex: (NSUInteger)index;

/** Called on self if a document deletion fails. */
- (void)deletionFailed: (RESTOperation*)op;

@end
