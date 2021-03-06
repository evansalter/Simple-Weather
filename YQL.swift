//
//  YQL.swift
//  YQLSwift
//
//  Created by Jake Lee on 1/25/15.
//  Copyright (c) 2015 JHL. All rights reserved.
//

import Foundation

struct YQL {
    private static let prefix:NSString = "https://query.yahooapis.com/v1/public/yql?&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=&q="
    
    static func query(statement:String) -> NSDictionary? {
        
        if (Reachability.reachabilityForInternetConnection()?.isReachable() != nil) {
            
            let escapedStatement = statement.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            let query = "\(prefix)\(escapedStatement!)"
            
            var results:NSDictionary? = nil
            var jsonError:NSError? = nil
            
            let jsonData: NSData?
            do {
                jsonData = try NSData(contentsOfURL: NSURL(string: query)!, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            } catch let error as NSError {
                jsonError = error
                jsonData = nil
            }
            
            if jsonData != nil {
                do {
                    try results = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                }
                catch {
                    print("error with YQL request")
                }
            }
            if jsonError != nil {
                NSLog( "ERROR while fetching/deserializing YQL data. Message \(jsonError!)" )
            }
            return results
            
        }
        else {
            
            return nil
            
        }
    }
}