//
//  ResultsTableViewController.swift
//  Simple Weather
//
//  Created by Evan Salter on 2015-06-15.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class ResultsTableViewController: UITableViewController {
    
    // ******************
    // MARK: - Properties
    // ******************
    var results: NSDictionary?
    var names: [String]?
    var provs: NSArray = NSArray()
    var countries: [String]?
    var woeids: [String]?
    
    var delegate: writeValueBackDelegate?

    // ************
    // MARK: - Misc
    // ************
    override func viewDidLoad() {
        super.viewDidLoad()
        
        names = results?.valueForKeyPath("query.results.place.name") as? [String]
        provs = results?.valueForKeyPath("query.results.place.admin1.content") as! NSArray
        countries = results?.valueForKeyPath("query.results.place.country.content") as? [String]
        woeids = results?.valueForKeyPath("query.results.place.woeid") as? [String]
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ******************************
    // MARK: - Table view data source
    // ******************************
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return results?.valueForKeyPath("query.count") as! Int
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath) 
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        // Configure the cell...
        
        let name = names?[indexPath.row]
        let prov: String? = provs[indexPath.row] as? String
        let country = countries?[indexPath.row]
        
        if prov == nil {
            cell.textLabel?.text = name! + ", " + country!
        }
        else {
            cell.textLabel?.text = name! + ", " + prov! + ", " + country!
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let name = names?[indexPath.row]
        let woeid = woeids?[indexPath.row]
        
        delegate?.writeValueBack(name!, woeid: woeid!)
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
