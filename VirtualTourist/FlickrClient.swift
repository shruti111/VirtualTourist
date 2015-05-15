//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 10/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import Foundation

class FlickrClient : NSObject {
   
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // Call HTTP Get Method to download data
    func taskForGETMethod(parameters: [String:AnyObject], completionHandler: (result:AnyObject!, error:NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set the parameters
        var mutableParameters = parameters

        //Build URL and configure Request
        let urlString = Constant.BaseURL  + FlickrClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        //Make the Request
        let task = session.dataTaskWithRequest(request) {data,response,downloadError in
            //Parse the data and use the data
            if let error = downloadError {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                FlickrClient.parseJSONWithmpletionHandler(data, completionHandler: completionHandler)
            }
        }
       // Start the request
        task.resume()
        return task
        
    }
    
    // Display error
    class func errorForData(data:NSData?, response:NSURLResponse?, error:NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String:AnyObject] {
            
            if let errorMessage = parsedResult[JSONResponseKeys.Message] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "VirtualTourist Error", code: 1, userInfo: userInfo)
            }
        }
        return error
    }
    
    //Parse JSON response
    class func parseJSONWithmpletionHandler(data:NSData, completionHandler:(result:AnyObject!, error:NSError?) -> Void) {
        var parsingError: NSError? = nil
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // Helper function: Given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
    
            // Make sure that it is a string value 
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    //MARK:- SharedInstance
    
    class func sharedInstance()-> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    //MARK:- Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
