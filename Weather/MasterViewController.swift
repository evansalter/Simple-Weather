//
//  MasterViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-19.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit
import iAd

class MasterViewController: UITableViewController, ADBannerViewDelegate, writeValueBackDelegate {
    
    // ******************
    // MARK: - Properties
    // ******************

    // iAd banner view
    var bannerView = ADBannerView(adType: ADAdType.Banner)
    
    // Bool stating whether the in-app purchase to remove ads has been purchased
    var IAPPurchased:Bool?
    
    // Results object returned from YQL request to be passed to the results view controller
    var resultsToPass: NSDictionary = NSDictionary()

    // ******************
    // MARK: - View Setup
    // ******************
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        IAPPurchased = loadSettings()
        
        //iAd banner
        if IAPPurchased == nil || IAPPurchased == false {
            bannerView.hidden = false
            self.canDisplayBannerAds = true
        }
        else {
            self.canDisplayBannerAds = false
            bannerView.hidden = true
        }
        self.bannerView.delegate = self
        self.bannerView.hidden = true
        
//        println(self.bannerView.bounds.height.description)
//        self.bannerView.bounds = CGRect(x: 0.0, y: 0.0, width: self.bannerView.bounds.width, height: 22.0)
        
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
            //bannerView?.removeFromSuperview()
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
    
    /**
        Loads the in-app purchase indicator from user defaults
    
        - returns: true if IAP has been purchased, false otherwise
    */
    func loadSettings() -> Bool {
        
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let savedData:Bool = (defaults.objectForKey("IAP") as? Bool) {
            return savedData
        }
        else {
            return false
        }
        
    }
    
    // ********************
    // MARK: - Share Button
    // ********************
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
        let alertVC = UIAlertController(title: "Share the love", message: "Tell your friends about Simple Weather!", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Keep it a secret", style: UIAlertActionStyle.Cancel, handler: nil)
        let shareAction = UIAlertAction(title: "Tell the world!", style: UIAlertActionStyle.Default) { (_) in
            self.socialShare()
        }
        
        alertVC.addAction(cancelAction)
        alertVC.addAction(shareAction)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
        
    }
    
    func socialShare() {
        
        let textToShare = "Check out this great weather app, Simple Weather!"
        
        if let websiteToShare = NSURL(string: "https://appsto.re/ca/JqGH7.i") {
            
            let objectsToShare = [textToShare, websiteToShare]
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
    
    // ***********
    // MARK: - iAd
    // ***********
    
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
    
    // ************************
    // MARK: - Adding Locations
    // ************************

    /**
        Inserts a new location into the location list.
        Called when the plus button is tapped
    */
    func insertNewObject(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "Add City", message: "Search for a city below.", preferredStyle: .Alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (_) in
            
            let cityTextField = alertController.textFields![0] 
            
            self.getPlaceName(cityTextField.text!)
            
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
    
    /**
        Searches the YQL geo database using the string entered to find the proper pace name.
        
        Outcomes:
    
        - If one location is returned, a confirmation dialog appears to confirm it is the correct location
        - If multiple locations are returned, a list showing them all appears and the user selects the correct one
    
        - parameter place: String containing the input from the user
    */
    func getPlaceName(place: String) {
        
        let results = YQL.query("SELECT * FROM geo.places WHERE text=\"" + place + "\" and placetype = \"town\"")
        var alertString = ""
        
        if results == nil {
            self.noNetworkErrorDialog()
        }
        else if place.characters.count < 4 {
            self.fourCharactersErrorDialog()
        }
        else if results?.valueForKeyPath("query.count") as! Double == 1 {
            let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
            let cityName = queryResults?.valueForKeyPath("place.name") as! String
            let countryName = queryResults?.valueForKeyPath("place.country.content") as! String
            var woeid = queryResults?.valueForKeyPath("place.woeid") as! String
            if Int(woeid) == 91982014 {
                woeid = "3369"
            }
            if let provName = queryResults?.valueForKeyPath("place.admin1.content") as? String {
                alertString = "Would you like to add " + cityName + ", " + provName + ", " + countryName + "?"
            }
            else {
                alertString = "Would you like to add " + cityName + ", " + countryName + "?"
            }
            confirmationDialog(alertString, name: cityName, woeid: woeid)

        }
        else if results?.valueForKeyPath("query.count") as! Double > 1 {
            let VC: AnyObject? = self.navigationController?.childViewControllers[0]
            resultsToPass = results!
            VC?.performSegueWithIdentifier("showResultsList", sender: self)
        }
        else {
            self.cityNotFoundDialog()
        }
        
    }
    
    /**
        Finds an image from Flickr for the newly added location based on image title, usage license, and tags.  The results are sorted by interestingness and the top one is used.
    
        - parameter place: String containing the name of the location
    
        - returns: NSDictionary containing url, author, name, ID, and author ID of the photo.  If no photo was found, all fields in the NSDictionary are empty
    */
    func getImage(place: String) -> NSDictionary? {
        
        // let results = YQL.query("SELECT * FROM flickr.photos.search WHERE api_key=\"5182195e863cee6875590c57b381657f\" and text=\"" + place + "\" and license=\"4\" | truncate(count=1)")
        
        let results = YQL.query("SELECT * FROM flickr.photos.search WHERE api_key=\"5182195e863cee6875590c57b381657f\" and text=\"" + place + "\" and license=\"4\" and tags=\"skyline, city, landscape, town, country, nature\" and sort=\"interestingness-desc\" | truncate(count=1)")
        
        if results?.valueForKeyPath("query.count") as! Double >= 1 {
            let queryResults = results?.valueForKeyPath("query.results") as! NSDictionary?
            let photoID = queryResults?.valueForKeyPath("photo.id") as! String
            print(photoID)
            let photoName = queryResults?.valueForKeyPath("photo.title") as! String
            let photoAuthorID = queryResults?.valueForKeyPath("photo.owner") as! String
            print(photoAuthorID)
            
            let results2 = YQL.query("SELECT * FROM flickr.people.info2 WHERE api_key=\"5182195e863cee6875590c57b381657f\" and user_id=\"" + photoAuthorID + "\"")
            let queryResults2 = results2?.valueForKeyPath("query.results") as! NSDictionary?
            let photoAuthor = queryResults2?.valueForKeyPath("person.username") as! String
            print(photoAuthor)
            
            let results3 = YQL.query("SELECT * FROM flickr.photos.sizes WHERE photo_id=\"" + photoID + "\" and api_key=\"5182195e863cee6875590c57b381657f\"")
            
            let queryResults3 = results3?.valueForKeyPath("query.results") as! NSDictionary?
            let urls = queryResults3?.valueForKeyPath("size.source") as! NSArray
            let url = urls[5] as! String
            
            let dict: NSDictionary = NSDictionary(dictionary: ["url":url, "photoAuthor":photoAuthor, "photoName":photoName, "photoID":photoID, "photoAuthorID":photoAuthorID])
            
            return dict
            
        }
        
        let dict: NSDictionary = NSDictionary(dictionary: ["url":"", "photoAuthor":"", "photoName":"", "photoID":"", "photoAuthorID":""])
        
        return dict
    
    }
    
    /**
        Dialog to confirm adding a city.  This appears when only one result it returned from the city search.
    
        Contents:
    
        - String asking the user to confirm it is the right location (city name, province/state, country)
        - "Add" button
        - "Cancel" button
    
        - parameter alertString: String containing message to display to the user
        - parameter name: String containing the name of the city
        - parameter woeid: String containing the woeid of the city
    */
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
    
    /**
        Adds the selected city to the table and loads in the image
    
        - parameter name: String containing the name of the city
        - parameter woeid: String containing the woeid of the city
    */
    func addLocation(name: String, woeid: String) {
        
        let location = Location(newName: name, newWoeid: woeid)
        allLocations.insert(location, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        let curCell: UITableViewCell = self.tableView.cellForRowAtIndexPath(indexPath)!
        
        let queue = NSOperationQueue()
        queue.addOperationWithBlock() {
            
            let dict = self.getImage(name)
            let url = dict?.valueForKey("url") as! String
            
            if url != "" {
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
    
    // MARK: - Error Dialogs
    
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
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = allLocations[indexPath.row]
            (segue.destinationViewController as! ForecastTableViewController).detailItem = object
            }
        }
        else if segue.identifier == "showResultsList" {
            let destinationVC = segue.destinationViewController as! ResultsTableViewController
            destinationVC.delegate = self
            destinationVC.results = resultsToPass
        }
    }
    
    func writeValueBack(name: String, woeid: String) {
        
        var found: Bool = false
        for l in allLocations {
            if l.woeid == woeid {
                found = true
            }
        }
        if found {
            //ERROR: Already added
            let alertString = name + " has already been added."
            self.navigationController?.popToRootViewControllerAnimated(true)
            self.cityExistsDialog(alertString)
        }
        else {
            self.addLocation(name, woeid: woeid)
            Location.saveLocations()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

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
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let item = allLocations[sourceIndexPath.row]
        allLocations.removeAtIndex(sourceIndexPath.row)
        allLocations.insert(item, atIndex: destinationIndexPath.row)
        Location.saveLocations()
    }


}

