//
//  ForecastTableViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-25.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class ForecastTableViewController: UITableViewController {

    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var copyrightButtonOutlet: UIButton!
    
    var item: Location = Location()
    var days: [String] = []
    var highs: [String] = []
    var lows: [String] = []
    var conditions: [String] = []
    var curTemp: String = ""
    var curCondition: String = ""
    var windChill: String = ""
    var windDirDeg: Double = 0
    var windDirStr: String = ""
    var windSpeed: Int = 0
    var windUnits: String = ""
    var units: String = ""
    
    var detailItem: Location? {
        didSet {
            // Update the view.
            item = detailItem!
            self.configureView()
        }
    }
    
    func configureView() {
        
        self.title = detailItem?.name
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        //self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    func loadSettings() -> Int {
        
        var defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if var savedData:Int = (defaults.objectForKey("unitSelector") as? Int) {
            return savedData
        }
        else {
            return 0
        }
        
    }
    
    func getForecast() {
        
        let u: String
        
        if loadSettings() == 0 {
            u = "c"
            units = "C"
            windUnits = "km/h"
        }
        else {
            u = "f"
            units = "F"
            windUnits = "mph"
        }
        
        let results = YQL.query("SELECT * FROM weather.forecast WHERE woeid=" + item.woeid + " and u=\"" + u + "\"")
        let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
        
        days = queryResults?.valueForKeyPath("channel.item.forecast.day") as! [String]
        highs = queryResults?.valueForKeyPath("channel.item.forecast.high") as! [String]
        lows = queryResults?.valueForKeyPath("channel.item.forecast.low") as! [String]
        conditions = queryResults?.valueForKeyPath("channel.item.forecast.text") as! [String]
        curTemp = queryResults?.valueForKeyPath("channel.item.condition.temp") as! String
        curCondition = queryResults?.valueForKeyPath("channel.item.condition.text") as! String
        windDirDeg = (queryResults?.valueForKeyPath("channel.wind.direction") as! NSString).doubleValue
        windSpeed = (queryResults?.valueForKeyPath("channel.wind.speed") as! NSString).integerValue
        windChill = queryResults?.valueForKeyPath("channel.wind.chill") as! String
        
        if windDirDeg >= 337.5 || windDirDeg < 22.5 {
            windDirStr = "N"
        }
        else if windDirDeg >= 22.5 && windDirDeg < 67.5 {
            windDirStr = "NE"
        }
        else if windDirDeg >= 67.5 && windDirDeg < 112.5 {
            windDirStr = "E"
        }
        else if windDirDeg >= 112.5 && windDirDeg < 157.5 {
            windDirStr = "SE"
        }
        else if windDirDeg >= 157.5 && windDirDeg < 202.5 {
            windDirStr = "S"
        }
        else if windDirDeg >= 202.5 && windDirDeg < 247.5 {
            windDirStr = "SW"
        }
        else if windDirDeg >= 247.5 && windDirDeg < 292.5 {
            windDirStr = "W"
        }
        else {
            windDirStr = "NW"
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = NSOperationQueue()
        queue.addOperationWithBlock() {
            self.getForecast()
            
            NSOperationQueue.mainQueue().addOperationWithBlock(){
                
                let range: NSRange = NSMakeRange(1, 1)
                let indexSet: NSIndexSet = NSIndexSet(indexesInRange: range)
                self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
                self.tableView.reloadData()
                
            }
            
        }
        
        if detailItem?.url == "" {
            copyrightLabel.text = ""
            copyrightButtonOutlet.enabled = false
        }
        else {
            let photoName = detailItem?.photoName
            let photoAuthor = detailItem?.photoAuthor
            
            copyrightLabel.text = "\"" + photoName! + "\" by " + photoAuthor! + ", used under CC-BY / Cropped from original"
            copyrightButtonOutlet.enabled = true
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    @IBAction func copyrightButtonPressed(sender: AnyObject) {
        
        let photoAuthorID = detailItem?.photoAuthorID
        let photoID = detailItem?.photoID
        let urlString = "https://flickr.com/photos/" + photoAuthorID! + "/" + photoID! + "/"
        //let escapedString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let url = NSURL(string: urlString)
        UIApplication.sharedApplication().openURL(url!)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        if section == 0 {
            return 1
        }
        else {
            return days.count
        }

    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 132
        }
        else {
            return 88
        }
        
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        
        if section == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("CurrentCell", forIndexPath: indexPath) as! UITableViewCell
            
            let row = indexPath.row
            let conditionLabel = cell.contentView.viewWithTag(5) as! UILabel
            let tempLabel = cell.contentView.viewWithTag(6) as! UILabel
            let windLabel = cell.contentView.viewWithTag(7) as! UILabel
            let windChillLabel = cell.contentView.viewWithTag(8) as! UILabel
            let nowLabel = cell.contentView.viewWithTag(9) as! UILabel

            
            conditionLabel.text = curCondition
            tempLabel.text = curTemp + "°" + units
            windLabel.text = "Wind: " + windSpeed.description + " " + windUnits + " " + windDirStr
            
            if windChill == curTemp {
                windChillLabel.text = ""
            }
            else {
                windChillLabel.text = "Feels like: " + windChill + "°" + units
            }

            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            if detailItem!.image != nil {
                conditionLabel.textColor = UIColor.whiteColor()
                tempLabel.textColor = UIColor.whiteColor()
                windLabel.textColor = UIColor.whiteColor()
                windChillLabel.textColor = UIColor.whiteColor()
                nowLabel.textColor = UIColor.whiteColor()
                
                let image: UIImage = (detailItem!.image as UIImage?)!
                let imageView: UIImageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFill
                imageView.layer.masksToBounds = true
                cell.backgroundView = imageView
                
                let overlay = CALayer()
                overlay.frame = cell.bounds
                overlay.backgroundColor = UIColor.blackColor().CGColor
                overlay.opacity = 0.2
                cell.layer.insertSublayer(overlay, atIndex: 1)
            }
            
            return cell
            
        }
        else {
        
            let cell = tableView.dequeueReusableCellWithIdentifier("ForecastCell", forIndexPath: indexPath) as! UITableViewCell

            // Configure the cell...
            
            let row = indexPath.row
            let dayLabel = cell.contentView.viewWithTag(1) as! UILabel
            let highLabel = cell.contentView.viewWithTag(2) as! UILabel
            let lowLabel = cell.contentView.viewWithTag(3) as! UILabel
            let conditionLabel = cell.contentView.viewWithTag(4) as! UILabel
            
            dayLabel.text = days[row]
            highLabel.text = highs[row] + "°" + units
            lowLabel.text = lows[row] + "°" + units
            conditionLabel.text = conditions[row]
            
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            return cell
        
        }

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
