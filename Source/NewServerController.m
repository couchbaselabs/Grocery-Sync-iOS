#import "NewItemViewController.h"
#import "NewServerController.h"
#import "RootViewController.h"
#import "CCouchDBServer.h"
#import "CCouchDBDatabase.h"
#import "CouchDBClientTypes.h"
#import "DatabaseManager.h"
#import "CouchDBClientTypes.h"
#import "CURLOperation.h"



@implementation NewServerController
@synthesize textView;
@synthesize delegate;
@synthesize couchbaseURL;
@synthesize items;


-(NSURL *)getCouchbaseURL {
	return self.couchbaseURL;
}


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc]
                                        initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                        target:self 
                                        action:@selector(done) 
                                        ] autorelease];
	self.navigationItem.rightBarButtonItem = doneButtonItem;
    
	UIBarButtonItem *cancelButtonItem = [[[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                          target:self
                                          action:@selector(cancel)
                                          ] autorelease];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
}

-(void)cancel
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

-(void)done
{
	NSString *text = textView.text;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:text forKey:@"servername"];
    [defaults synchronize];
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
	
}





-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[textView becomeFirstResponder];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [items release];
    [super dealloc];
}


@end
