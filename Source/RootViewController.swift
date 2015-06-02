//
//  RootViewController.swift
//  Grocery Sync
//
//  Copyright (c) 2014 Couchbase Inc. All rights reserved.
//


import UIKit


class RootViewController: UIViewController, UIAlertViewDelegate {

    var database: CBLDatabase!

    var progressBar: UIProgressView!

    @IBOutlet private var tableView :UITableView!
    @IBOutlet private var dataSource: CBLUITableSource!
    @IBOutlet private var addItemTextField: UITextField!
    @IBOutlet private var addItemBackground: UIImageView!


    //MARK: - Initialization

    
    func useDatabase(database: CBLDatabase!) -> Bool {
        if database == nil {
            return false
        }
        self.database = database

        // Define a view with a map function that indexes to-do items by creation date:
        database.viewNamed("byDate").setMapBlock("2") {
            (doc, emit) in
            if let dateObj: AnyObject = doc["created_at"] {
                if let date = dateObj as? String {
                    emit(date, doc)
                }
            }
        }

        // ...and a validation function requiring parseable dates:
        database.setValidationNamed("created_at") {
            (newRevision, context) in
            if !newRevision.isDeletion {
                if let dateObj: AnyObject = newRevision.properties?["created_at"] {
                    if let date = dateObj as? String {
                        if NSDate.withJSONObject(date) == nil {
                            context.rejectWithMessage("invalid date \(date)")
                        }
                    }
                }
            }
        }
        return true
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the "Clean" button:
        let deleteButton = UIBarButtonItem(
            title:  "Clean",
            style:  .Plain,
            target: self,
            action: "deleteCheckedItems:")
        self.navigationItem.leftBarButtonItem = deleteButton

        // Initialize the "Follow" button:
        let followButton = UIBarButtonItem(title: "Follow", style: .Plain, target: self, action: "openFollow:")
        followButton.enabled = true
        self.navigationItem.rightBarButtonItem = followButton

        // Initialize the sync progress bar:
        /*
        progressBar = UIProgressView(progressViewStyle: .Bar)
        var frame = progressBar.frame
        frame.size.width = self.view.frame.size.width / 4
        progressBar.frame = frame
        let progressItem = UIBarButtonItem(customView: progressBar)
        progressItem.enabled = false
        self.navigationItem.rightBarButtonItem = progressItem
        */

        // Customize the table view style:
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.clearColor()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            addItemBackground.frame = CGRectMake(45, 8, 680, 44)
            addItemTextField.frame = CGRectMake(56, 8, 665, 43)
        }

        // Database-related initialization:
        if useDatabase(appDelegate.database) {
            // Create a query sorted by descending date, i.e. newest items first:
            let query = database.viewNamed("byDate").createQuery().asLiveQuery()
            query.descending = true

            // Plug the query into the CBLUITableSource, which will use it to drive the table view.
            // (The CBLUITableSource uses KVO to observe the query's .rows property.)
            self.dataSource.query = query
            self.dataSource.labelProperty = "text"    // Document property to display in the cell label
        }
    }


    //MARK: - Table UI


    private let kBGColor : UIColor = {return UIColor(patternImage: UIImage(named:"item_background")!)}()


    // Customize the appearance of table view cells.
    func couchTableSource(
        source: CBLUITableSource!,
        willUseCell cell: UITableViewCell!,
        forRow row: CBLQueryRow!)
    {
        // Set the cell background and font:
        cell.backgroundColor = kBGColor
        cell.selectionStyle = .Gray

        cell.textLabel!.font = UIFont(name: "Helvetica", size: 18.0)
        cell.textLabel!.backgroundColor = UIColor.clearColor()
        
        // Configure the cell contents. Our view's map function (above) copies the document properties
        // into its value, so we can read them from there without having to load the document.
        let rowValue = row.value as? NSDictionary
        let checked = (rowValue?["check"] as? Bool) ?? false
        if checked {
            cell.textLabel!.textColor = UIColor.grayColor()
            cell.imageView!.image = UIImage(named: "list_area___checkbox___checked")
        } else {
            cell.textLabel!.textColor = UIColor.blackColor()
            cell.imageView!.image = UIImage(named: "list_area___checkbox___unchecked")
        }
        // cell.textLabel.text is already set, thanks to setting up labelProperty above.
    }


    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 50
    }


    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // Ask the CBLUITableSource for the corresponding query row, and get its document:
        if let row = self.dataSource.rowAtIndex(UInt(indexPath.row)) {
            var error: NSError?
            let newRev = row.document?.update(&error) {
                (rev: CBLUnsavedRevision!) -> Bool in
                // Toggle the document's 'checked' property:
                let wasChecked = (rev["check"] as? Bool) ?? false
                rev["check"] = !wasChecked
                return true
            }

            if newRev == nil {
                self.appDelegate.showAlert("Failed to update item", forError: error)
            }
        }
    }


    // Returns all the items that have been checked-off, as an array of CBLDocuments.
    var checkedDocuments :[CBLDocument] {
        // (If there were a whole lot of documents, this would be more efficient with a custom query.)
        let rows = self.dataSource.rows as! [CBLQueryRow]
        return rows.filter {
            if let value = $0.value as? NSDictionary,
                check = value["check"] as? Bool {
                    return check
            }
            return false
        }.map { $0.document! }
    }


    // Invoked by the "Clean Up" button.
    func deleteCheckedItems() {
        let numChecked = self.checkedDocuments.count
        if numChecked == 0 {
            return
        }

        let itemWord = numChecked==1 ? "item" : "items"
        let message = "Are you sure you want to remove the \(numChecked) checked-off \(itemWord)?"

        let alert = UIAlertView(
            title: "Remove Completed Items?",
            message: message,
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Remove")
        alert.show()
    }


    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            return
        }
        // Tell the CBLUITableSource to delete the documents, instead of doing it directly.
        // This lets it tell the table-view the rows are going away, so the table display can animate.
        var error: NSError?
        if !dataSource.deleteDocuments(self.checkedDocuments, error: &error) {
            self.appDelegate.showAlert("Failed to delete items", forError: error)
        }
    }


    //MARK: - Text Entry Field

    
    // Highlight the text field when input begins.
    func textFieldDidBeginEditing(textField: UITextField!) {
        addItemBackground.image = UIImage(named: "textfield___active.png")
    }


    // Un-highlight the text field when input ends.
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        addItemBackground.image = UIImage(named: "textfield___inactive.png")
        return true
    }


    // Add a new item when text input ends.
    func textFieldDidEndEditing(textField: UITextField!) {
        // Get the name of the item from the text field:
        let text = addItemTextField.text
        if text.isEmpty {
            return
        }
        addItemTextField.text = nil

        let properties: [NSObject : AnyObject] = [
            "text": text,
            "check": false,
            "created_at": CBLJSON.JSONObjectWithDate(NSDate())]

        // Save the document:
        let doc = database.createDocument()
        var error: NSError?
        if doc.putProperties(properties, error: &error) == nil {
            self.appDelegate.showAlert("Couldn't save new item", forError: error)
        }
    }


    //MARK: - Follow controller


    func openFollow(sender: AnyObject) {
        println("FOLLOW")
        var ctrlr = FollowViewController(peerSyncMgr: appDelegate.peerSyncMgr)
        self.navigationController!.pushViewController(ctrlr, animated: true)
    }


    // Returns the singleton DemoAppDelegate object.
    var appDelegate : DemoAppDelegate {
        return UIApplication.sharedApplication().delegate as! DemoAppDelegate
    }

}
