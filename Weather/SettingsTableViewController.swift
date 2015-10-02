//
//  SettingsTableViewController.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-22.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class SettingsTableViewController: UITableViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver, MFMailComposeViewControllerDelegate {
    
    // ******************
    // MARK: - Properties
    // ******************
    @IBOutlet weak var IAPButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var unitSelectorOutlet: UISegmentedControl!
    var IAPPurchased: Bool?
    
    let kUnitSelector = "unitSelector"
    let kIAP = "IAP"
    
    var product_id: NSString = NSString()

    // *******************
    // MARK: - View config
    // *******************
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettings()
        
        product_id = "iap.remove.ads"
        SKPaymentQueue.defaultQueue().addTransactionObserver(self as SKPaymentTransactionObserver)
        
        if IAPPurchased == nil || IAPPurchased == false {
            IAPButton.setTitle("Purchase", forState: UIControlState.Normal)
            IAPButton.enabled = true
            restoreButton.enabled = true
        }
        else {
            IAPButton.setTitle("Already Purchased", forState: UIControlState.Normal)
            IAPButton.enabled = false
            restoreButton.enabled = false
        }
        
        self.tableView.allowsSelection = false
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidDisappear(animated: Bool) {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    @IBAction func unitSelectorAction(sender: AnyObject) {
        
        saveSettings()
        
    }
    
    // ****************
    // MARK: - Settings
    // ****************
    func loadSettings() {
        
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let savedData:Int = (defaults.objectForKey(kUnitSelector) as? Int) {
            unitSelectorOutlet.selectedSegmentIndex = savedData
        }
        if let savedData2:Bool = (defaults.objectForKey(kIAP) as? Bool) {
            IAPPurchased = savedData2
        }
        
    }
    
    func saveSettings() {
        
        NSUserDefaults.standardUserDefaults().setObject(unitSelectorOutlet.selectedSegmentIndex, forKey: kUnitSelector)
        NSUserDefaults.standardUserDefaults().setObject(IAPPurchased, forKey: kIAP)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    

    // *********************
    // MARK: - Error Dialogs
    // *********************
    func noNetworkErrorDialog() {
        
        let alertController = UIAlertController(title: "No Network Connection", message: "Please check your network connection and try again.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default ) { (action) in
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func noConfiguredAccountError() {
        
        let alertController = UIAlertController(title: "Can't send email", message: "Your device does not have any email accounts configured.  If you wish, you can visit our support page and submit your feedback there.", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "Visit Support Page", style: .Default ) { (action) in
            UIApplication.sharedApplication().openURL(NSURL(string: "http://evansalter.com/simple-weather-feedback/")!)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default ) { (action) in
        }
        alertController.addAction(OKAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    // ***********
    // MARK: - IAP
    // ***********
    @IBAction func restoreButtonPressed(sender: AnyObject) {
        
        if (Reachability.reachabilityForInternetConnection()?.isReachable() != nil) {

        
            if (SKPaymentQueue.canMakePayments()) {
                SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
            }
            else {
                print("Cannot make purchases")
            }
            
        }
        else {
            self.noNetworkErrorDialog()
        }
        
    }
    
    
    @IBAction func purchaseButtonPressed(sender: AnyObject) {
        
        if (Reachability.reachabilityForInternetConnection()?.isReachable() != nil) {
        
            print("About to fetch the products")
            // We check that we are allowed to make the purchase.
            if SKPaymentQueue.canMakePayments() {
//                let productID:NSSet = NSSet(object: self.product_id!);
                let productID:Set<String> = Set<String>(arrayLiteral: (self.product_id as? String)!)
                let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<String>);
                productsRequest.delegate = self as SKProductsRequestDelegate
                productsRequest.start()
                print("Fetching Products")
            }
            else {
                print("Cannot make purchases")
            }
            
        }
        else {
            self.noNetworkErrorDialog()
        }
        
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("got the request from Apple")
        let count: Int = response.products.count
        if count > 0 {
            var validProducts = response.products
            let validProduct: SKProduct = response.products[0] 
            if validProduct.productIdentifier == self.product_id {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                buyProduct(validProduct)
            }
            else {
                print(validProduct.productIdentifier)
            }
        }
        else {
            print("nothing")
        }
    }
    
    func buyProduct(product: SKProduct) {
        print("Sending the Payment Request to Apple")
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Received Payment Transaction Response from Apple")
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .Purchased:
                    IAPPurchased = true
                    saveSettings()
                    //self.tableView.reloadData()
                    viewDidLoad()
                    print("Product Purchased")
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    break;
                case .Failed:
                    print("Purchase Failed")
                    IAPPurchased = false
                    saveSettings()
                    //purchase failed
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    break;
                case .Restored:
                    print("Purchase Restored")
                    IAPPurchased = true
                    saveSettings()
                    // self.tableView.reloadData()
                    viewDidLoad()
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    break;
                default:
                    //SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                }
            }
        }
    }

    // *********************
    // MARK: - Support Email
    // *********************
    @IBAction func supportButtonPressed(sender: UIBarButtonItem) {
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = configuredMailComposeViewController()
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        }
        else {
            self.noConfiguredAccountError()
        }
        
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["support@evansalter.com"])
        mailComposerVC.setSubject("Simple Weather Support")
        mailComposerVC.setMessageBody("Enter your issue below...\n\n", isHTML: false)
        
        return mailComposerVC
        
    }
    
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Potentially incomplete method implementation.
//        // Return the number of sections.
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete method implementation.
//        // Return the number of rows in the section.
//        return 0
//    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

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
