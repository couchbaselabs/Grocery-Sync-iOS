//
//  FollowViewController.swift
//  PeerSync
//
//  Created by Jens Alfke on 5/18/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

import UIKit

/** A view controller that manages "following" (pulling from) peers on the LAN.
    Create an instance with init, then push it onto your navigation controller.
    It will pop itself when the user presses the Save or Cancel button. */
class FollowViewController: UITableViewController {

    var peerSyncMgr: PeerSyncManager! = nil

    var peers = [Peer]()
    var offlinePeers = [Peer]()
    var pairings = PeerSet()

    private var obsPeer: Observer!

    private var saveButton: UIBarButtonItem!

    init(peerSyncMgr: PeerSyncManager) {
        super.init(style: .Plain)
        self.peerSyncMgr = peerSyncMgr
    }

    // Shouldn't be necessary, but UIKit tries to call it during the super.init call above...
    override init!(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        pairings = peerSyncMgr.pairing.pairings
        self.updatePeers()
        obsPeer = peerSyncMgr.peerBrowser.observe(keyPath: "peers") { [unowned self] in
            self.updatePeers()
            self.tableView.reloadData()
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        self.navigationItem.leftBarButtonItem = cancelButton
        saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save:")
        saveButton.enabled = false
        self.navigationItem.rightBarButtonItem = saveButton
    }

    private func updatePeers() {
        self.peers = sorted(peerSyncMgr.peerBrowser.peers, {$0.nickname < $1.nickname})
        self.offlinePeers = sorted(peerSyncMgr.offlinePairedPeers, {$0.nickname < $1.nickname})
    }


    func cancel(sender: AnyObject) {
        println("CANCEL")
        self.navigationController!.popViewControllerAnimated(true)
    }

    func save(sender: AnyObject) {
        println("SAVE")
        peerSyncMgr.pairing.pairings = pairings
        self.navigationController!.popViewControllerAnimated(true)
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (offlinePeers.count > 0) ? 2 : 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["On your network", "Offline Peers"][section]
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return peers.count
        } else {
            return offlinePeers.count
        }
    }

    func peerAtPath(indexPath: NSIndexPath) -> Peer {
        let list = (indexPath.section == 0) ? peers : offlinePeers
        return list[indexPath.row]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let peer = peerAtPath(indexPath)
        let paired = pairings[peer.UUID] != nil

        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel!.text = peer.nickname
        let fontSize = cell.textLabel!.font.pointSize
        cell.textLabel!.font = paired ? UIFont.boldSystemFontOfSize(fontSize) : UIFont.systemFontOfSize(fontSize)
        cell.accessoryType = paired ? .Checkmark : .None
        return cell
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        pairings ^= peerAtPath(indexPath);  // Toggle the presence of the peer
        saveButton.enabled = (pairings != peerSyncMgr.pairing.pairings)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        return nil
    }

    private static var pairedIcon = UIImage(named: "paired")

}

