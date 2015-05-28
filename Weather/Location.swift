//
//  Locations.swift
//  Weather
//
//  Created by Evan Salter on 2015-05-19.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

var allLocations:[Location] = []
var currentLocationIndex = -1
var locationTable:UITableView?

let kAllLocations = "locations"

class Location: NSObject {
    
    var name: String
    var woeid: String
    var image: UIImage?
    var imageData: NSData?
    var photoAuthor: String
    var photoName: String
    var photoID: String
    var photoAuthorID: String
    var url: String
    
    override init() {
        name = ""
        woeid = ""
        image = nil
        imageData = nil
        photoAuthor = ""
        photoName = ""
        photoID = ""
        photoAuthorID = ""
        url = ""
    }
    
    init(newName: String, newWoeid: String){
        
        name = newName
        woeid = newWoeid
        image = nil
        imageData = nil
        photoAuthor = ""
        photoName = ""
        photoID = ""
        photoAuthorID = ""
        url = ""
        
    }
    
    func dictionary() -> NSDictionary {
        if image == nil {
            return["name":name,"woeid":woeid]
        }
        else {
            let imageData: NSData = UIImagePNGRepresentation(image)
            return["name":name,"woeid":woeid,"imageData":imageData,"photoAuthor":photoAuthor,"photoName":photoName,"photoID":photoID,"photoAuthorID":photoAuthorID,"url":url]
        }
    }
    
    class func saveLocations(){
        var aDictionaries:[NSDictionary] = []
        for var i:Int = 0; i < allLocations.count; i++ {
            aDictionaries.append(allLocations[i].dictionary())
        }
        NSUserDefaults.standardUserDefaults().setObject(aDictionaries, forKey: kAllLocations)
    }
    
    class func loadLocations(){
        var defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var savedData:[NSDictionary]? = defaults.objectForKey(kAllLocations) as? [NSDictionary]
        if let data:[NSDictionary] = savedData {
            for var i:Int = 0; i < data.count; i++ {
                var l:Location = Location()
                l.setValuesForKeysWithDictionary(data[i] as [NSObject : AnyObject])
                if l.imageData != nil {
                    l.image = UIImage(data: l.imageData!)
                }
                allLocations.append(l)
            }
        }
    }
    
}
