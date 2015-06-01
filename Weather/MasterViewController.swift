//
//  MasterViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-19.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit
import iAd

class MasterViewController: UITableViewController, ADBannerViewDelegate {
    
    var objects = [AnyObject]()
    var bannerView:ADBannerView?
    var IAPPurchased:Bool?


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        IAPPurchased = loadSettings()
        
        //iAd banner
        if IAPPurchased == nil || IAPPurchased == false {
            bannerView?.hidden = false
            self.canDisplayBannerAds = true
        }
        else {
            self.canDisplayBannerAds = false
            bannerView?.removeFromSuperview()
            bannerView?.hidden = true
            bannerView = nil
        }
        self.bannerView?.delegate = self
        self.bannerView?.hidden = true
        
        Location.loadLocations()
        locationTable = self.tableView
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        
        IAPPurchased = loadSettings()
        
        if IAPPurchased != nil && IAPPurchased == true {
            self.canDisplayBannerAds = false
            bannerView?.removeFromSuperview()
            bannerView?.hidden = true
            bannerView = nil
        }
        else {
            bannerView?.hidden = false
            self.canDisplayBannerAds = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        if IAPPurchased != nil && IAPPurchased == true {
            self.bannerView?.hidden = true
        }
        else {
            self.bannerView?.hidden = false
        }
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return willLeave
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.bannerView?.hidden = true
    }
    
    func loadSettings() -> Bool {
        
        var defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if var savedData:Bool = (defaults.objectForKey("IAP") as? Bool) {
            return savedData
        }
        else {
            return false
        }
        
    }

    func insertNewObject(sender: AnyObject) {
//        allLocations.insert("test", atIndex: 0)
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
//        self.performSegueWithIdentifier("showDetail", sender: self)
        
        let alertController = UIAlertController(title: "Add City", message: "Search for a city below.", preferredStyle: .Alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (_) in
            
            let cityTextField = alertController.textFields![0] as! UITextField
            
            self.getPlaceName(cityTextField.text)
            
        }
        
        submitAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            
            textField.placeholder = "City name"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                submitAction.enabled = textField.text != ""
            }
            
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func getPlaceName(place: String) {
        
        let results = YQL.query("SELECT * FROM geo.places WHERE text=\"" + place + "\" and placetype = \"town\"|truncate(count=1)")
        var alertString = ""
        
        if results == nil {
            self.noNetworkErrorDialog()
        }
        else if count(place) < 4 {
            self.fourCharactersErrorDialog()
        }
        else if results?.valueForKeyPath("query.count") as! Double >= 1 {
            let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
            let cityName = queryResults?.valueForKeyPath("place.name") as! String
            let provName = queryResults?.valueForKeyPath("place.admin1.content") as! String
            let countryName = queryResults?.valueForKeyPath("place.country.content") as! String
            let woeid = queryResults?.valueForKeyPath("place.woeid") as! String
            
            alertString = "Would you like to add " + cityName + ", " + provName + ", " + countryName + "?"
            confirmationDialog(alertString, name: cityName, woeid: woeid)

        }
        else {
            self.cityNotFoundDialog()
        }
        
    }
    
    func getImage(place: String) -> NSDictionary? {
        
        // let results = YQL.query("SELECT * FROM flickr.photos.search WHERE api_key=\"5182195e863cee6875590c57b381657f\" and text=\"" + place + "\" and license=\"4\" | truncate(count=1)")
        
        let results = YQL.query("SELECT * FROM flickr.photos.search WHERE api_key=\"5182195e863cee6875590c57b381657f\" and text=\"" + place + "\" and license=\"4\" and tags=\"skyline, city, landscape, town, country, nature\" and sort=\"interestingness-desc\" | truncate(count=1)")
        
        if results?.valueForKeyPath("query.count") as! Double >= 1 {
            let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
            let photoID = queryResults?.valueForKeyPath("photo.id") as! String
            println(photoID)
            let photoName = queryResults?.valueForKeyPath("photo.title") as! String
            let photoAuthorID = queryResults?.valueForKeyPath("photo.owner") as! String
            println(photoAuthorID)
            
            let results2 = YQL.query("SELECT * FROM flickr.people.info2 WHERE api_key=\"5182195e863cee6875590c57b381657f\" and user_id=\"" + photoAuthorID + "\"")
            let queryResults2 = results2?.valueForKeyPath("query.results") as! NSDictionary?
            let photoAuthor = queryResults2?.valueForKeyPath("person.username") as! String
            println(photoAuthor)
            
            let results3 = YQL.query("SELECT * FROM flickr.photos.sizes WHERE photo_id=\"" + photoID + "\" and api_key=\"5182195e863cee6875590c57b381657f\"")
            
            let queryResults3 = results3?.valueForKeyPath("query.results") as! NSDictionary?
            let urls = queryResults3?.valueForKeyPath("size.source") as! NSArray
            let url = urls[5] as! String
            
            let dict: NSDictionary = NSDictionary(dictionary: ["url":url, "photoAuthor":photoAuthor, "photoName":photoName, "photoID":photoID, "photoAuthorID":photoAuthorID])
            
            return dict
            
            //return url
            
        }
        
        let dict: NSDictionary = NSDictionary(dictionary: ["url":"", "photoAuthor":"", "photoName":"", "photoID":"", "photoAuthorID":""])
        
        return dict
    
    }
    
    func confirmationDialog(alertString: String, name: String, woeid: String) {
        
        let alertController = UIAlertController(title: "Confirmation", message: alertString, preferredStyle: .Alert)
        
        let addAction = UIAlertAction(title: "Add", style: .Default) { (action) in
            //println(alertString)
            
            var found: Bool = false
            for l in allLocations {
                if l.woeid == woeid {
                    found = true
                }
            }
            if found {
                //ERROR: Already added
                let alertString = name + " has already been added."
                self.cityExistsDialog(alertString)
            }
            else {
                self.addLocation(name, woeid: woeid)
                Location.saveLocations()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
        }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func fourCharactersErrorDialog() {
        
        let alertController = UIAlertController(title: "Error", message: "Please enter at least 4 characters.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (aciton) in
            self.insertNewObject(self)
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func noNetworkErrorDialog() {
        
        let alertController = UIAlertController(title: "No Network Connection", message: "Please check your network connection and try again.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default ) { (action) in
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func cityNotFoundDialog() {
        
        let alertController = UIAlertController(title: "City Not Found", message: "Please check the spelling and try again.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default ) { (action) in
            self.insertNewObject(self)
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func cityExistsDialog(errorString: String) {
        
        let alertController = UIAlertController(title: "Error", message: errorString, preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            self.insertNewObject(self)
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func addLocation(name: String, woeid: String) {
        
        let location = Location(newName: name, newWoeid: woeid)
        allLocations.insert(location, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        let queue = NSOperationQueue()
        queue.addOperationWithBlock() {
        
            let dict = self.getImage(name)
            let url = dict?.valueForKey("url") as! String
        
            if url != "" {
                let curCell: UITableViewCell = self.tableView.cellForRowAtIndexPath(indexPath)!
                let imageData = NSData(contentsOfURL: NSURL(string: url as String)!)
                let image: UIImage = UIImage(data: imageData!)!
                let imageView: UIImageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFill
                imageView.layer.masksToBounds = true
                curCell.backgroundView = imageView
                location.image = image
                location.photoAuthor = dict?.valueForKey("photoAuthor") as! String
                location.photoAuthorID = dict?.valueForKey("photoAuthorID") as! String
                location.photoID = dict?.valueForKey("photoID") as! String
                location.photoName = dict?.valueForKey("photoName") as! String
                location.url = dict?.valueForKey("url") as! String
            }
            else {
                location.image = nil
                location.photoAuthor = ""
                location.photoAuthorID = ""
                location.photoID = ""
                location.photoName = ""
                location.url = ""
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                Location.saveLocations()
                
            }
            
        }

        
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = allLocations[indexPath.row]
            (segue.destinationViewController as! ForecastTableViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allLocations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        let object = allLocations[indexPath.row] as Location
//        cell.textLabel!.text = object.name
//        cell.textLabel!.textColor = UIColor.whiteColor()
        
        let label: UILabel = cell.viewWithTag(1) as! UILabel
        label.text = object.name
        label.textColor = UIColor.whiteColor()
        
        let imageView: UIImageView = UIImageView(image: object.image)
        imageView.contentMode = .ScaleAspectFill
        imageView.layer.masksToBounds = true
        cell.backgroundView = imageView
        
        let gradient = CAGradientLayer()
        gradient.frame = cell.bounds
        gradient.colors = [UIColor.clearColor().CGColor, UIColor.clearColor(), UIColor.blackColor().CGColor]
        cell.layer.insertSublayer(gradient, atIndex: 1)
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            allLocations.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            Location.saveLocations()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }


}

