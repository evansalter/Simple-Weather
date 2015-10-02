//
//  ForecastTableViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-25.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class ForecastTableViewController: UITableViewController {

    // ******************
    // MARK: - Properties
    // ******************
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
    
    // *******************
    // MARK: - View config
    // *******************
    func configureView() {
        
        self.title = detailItem?.name
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Help", style: UIBarButtonItemStyle.Plain, target: self, action: "helpButtonPressed:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        copyrightLabel.hidden = true
        
        let queue = NSOperationQueue()
        queue.addOperationWithBlock() {
            self.getForecast()
            
            NSOperationQueue.mainQueue().addOperationWithBlock(){
                
                let range: NSRange = NSMakeRange(1, 1)
                let indexSet: NSIndexSet = NSIndexSet(indexesInRange: range)
                self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
                self.tableView.reloadData()
                self.copyrightLabel.hidden = false
                
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
    
    override func viewWillAppear(animated: Bool) {
        //self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        //self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    // **********************
    // MARK: - Button Actions
    // **********************
    func helpButtonPressed(barButton: UIBarButtonItem){
        
        let alertVC = UIAlertController(title: "Help", message: "Share the current weather or forecast by long-pressing on any of the entries below.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alertVC.addAction(OKAction)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
        
    }
    
    @IBAction func copyrightButtonPressed(sender: AnyObject) {
        
        let photoAuthorID = detailItem?.photoAuthorID
        let photoID = detailItem?.photoID
        let urlString = "https://flickr.com/photos/" + photoAuthorID! + "/" + photoID! + "/"
        //let escapedString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let url = NSURL(string: urlString)
        UIApplication.sharedApplication().openURL(url!)
        
    }

    // ****************
    // MARK: - Settings
    // ****************
    func loadSettings() -> Int {
        
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let savedData:Int = (defaults.objectForKey("unitSelector") as? Int) {
            return savedData
        }
        else {
            return 0
        }
        
    }
    
    // ****************
    // MARK: - Forecast
    // ****************
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
        
        if results == nil {
            self.noNetworkErrorDialog()
        }
        else {
            let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
            
            if queryResults?.valueForKeyPath("channel.title") as! String == "Yahoo! Weather - Error" {
                forecastErrorDialog()
            }
            else {
                days = queryResults?.valueForKeyPath("channel.item.forecast.day") as! [String]
                highs = queryResults?.valueForKeyPath("channel.item.forecast.high") as! [String]
                lows = queryResults?.valueForKeyPath("channel.item.forecast.low") as! [String]
                conditions = queryResults?.valueForKeyPath("channel.item.forecast.text") as! [String]
                curTemp = queryResults?.valueForKeyPath("channel.item.condition.temp") as! String
                curCondition = queryResults?.valueForKeyPath("channel.item.condition.text") as! String
                windDirDeg = (queryResults?.valueForKeyPath("channel.wind.direction") as! NSString).doubleValue
                windSpeed = (queryResults?.valueForKeyPath("channel.wind.speed") as! NSString).integerValue
                windChill = queryResults?.valueForKeyPath("channel.wind.chill") as! String
                
            }
            
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

        
    }
    
    // *********************
    // MARK: - Error Dialogs
    // *********************
    func noNetworkErrorDialog() {
        
        let alertController = UIAlertController(title: "No Network Connection", message: "Please check your network connection and try again.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default ) { (action) in
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func forecastErrorDialog() {
        
        let alertController = UIAlertController(title: "Error Getting Forecast", message: "There was an error getting the forecast.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (aciton) in
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    // ************
    // MARK: - Misc
    // ************
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
            
            let cell = tableView.dequeueReusableCellWithIdentifier("CurrentCell", forIndexPath: indexPath) 
            
            let LPRecognizer = UILongPressGestureRecognizer(target: self, action: "cellLongPressedActionSection0:")
            LPRecognizer.minimumPressDuration = 1.0
            
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
            
            cell.addGestureRecognizer(LPRecognizer)
            
            return cell
            
        }
        else {
        
            let cell = tableView.dequeueReusableCellWithIdentifier("ForecastCell", forIndexPath: indexPath) 
            
            let LPRecognizer = UILongPressGestureRecognizer(target: self, action: "cellLongPressedActionSection1:")
            LPRecognizer.minimumPressDuration = 1.0

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
            
            cell.addGestureRecognizer(LPRecognizer)
            
            return cell
        
        }

    }
    
    func cellLongPressedActionSection0(gestureRecognizer: UIGestureRecognizer) {
        
        let cell = gestureRecognizer.view as! UITableViewCell
        
        var shareString: String
        
        let city = self.title
        let condition = (cell.viewWithTag(5) as! UILabel).text
        let temp = (cell.viewWithTag(6) as! UILabel).text
        let wind = (cell.viewWithTag(7) as! UILabel).text
        let feels = (cell.viewWithTag(8) as! UILabel).text
        
        if feels == "" {
            shareString = "Current weather in \(city!): \(condition!), \(temp!), \(wind!)."
        }
        else {
            shareString = "Current weather in \(city!): \(condition!), \(temp!), \(wind!), \(feels!)."
        }
        
        shareString = shareString + "  Provided by Simple Weather!"
        socialShare(shareString)
        
    }
    
    func cellLongPressedActionSection1(gestureRecognizer: UIGestureRecognizer) {
        
        let cell = gestureRecognizer.view as! UITableViewCell
        
        var shareString: String
        
        let city = self.title
        let day = (cell.viewWithTag(1) as! UILabel).text
        let high = (cell.viewWithTag(2) as! UILabel).text
        let low = (cell.viewWithTag(3) as! UILabel).text
        let condition = (cell.viewWithTag(4) as! UILabel).text

        shareString = "Weather for \(day!) in \(city!): \(condition!) with a high of \(high!) and low of \(low!)."
        
        shareString = shareString + "  Provided by Simple Weather!"
        socialShare(shareString)
        
    }
    
    func socialShare(shareString: String) {
        
        if let websiteToShare = NSURL(string: "https://appsto.re/ca/JqGH7.i") {
            
            let objectsToShare = [shareString, websiteToShare]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.excludedActivityTypes = [UIActivityTypePrint,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo]
            
            self.presentViewController(activityVC, animated: true, completion: nil)
            
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
