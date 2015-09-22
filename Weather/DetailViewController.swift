//
//  DetailViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-19.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController {

    // ******************
    // MARK: - Properties
    // ******************
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    var item: Location = Location()
    
    var detailItem: Location? {
        didSet {
            // Update the view.
            item = detailItem!
            self.configureView()
        }
    }
    
    // ****************
    // MARK: - Settings
    // ****************
    func loadSettings() -> Int {
        
        var defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if var savedData:Int = (defaults.objectForKey("settings") as? Int) {
            return savedData
        }
        else {
            return 0
        }
        
    }
    
    // ****************
    // MARK: - Forecast
    // ****************
    func getForecast() -> [String] {
        
        let u: String
        
        if loadSettings() == 0 {
            u = "c"
        }
        else {
            u = "f"
        }
        
        let results = YQL.query("SELECT * FROM weather.forecast WHERE woeid=" + item.woeid + " and u=\"" + u + "\"")
        let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
        println(queryResults)
        println()
        println(queryResults?.valueForKeyPath("channel.item.condition.text") as! String)
        println(queryResults?.valueForKeyPath("channel.item.condition.temp") as! String)
        
        return queryResults?.valueForKeyPath("channel.item.forecast.day") as! [String]
        
    }

    // *******************
    // MARK: - View Config
    // *******************
    func configureView() {
        // Update the user interface for the detail item.
        if let detail: Location = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = "Name: " + detail.name + "; woeid: " + detail.woeid
            }
            self.title = detail.name
            
        }
        
        let forecast = self.getForecast()
        
        let count = forecast.count
        for var i = 0; i < count; i++ {
            
            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
            cell!.textLabel?.text = forecast[i]
            
        }
        
        // getForecast()
        
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        let forecast = getForecast()
        let object = forecast[indexPath.row]
        cell.textLabel?.text = object
        
        
        
        
        return cell
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

