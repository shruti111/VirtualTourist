//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 10/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import Foundation

extension FlickrClient {
  
    // Flickr conveniece method to download image set based on location and page number
    
    func getImageFromFlickrByLatLonWithPage(methodArguments: [String : AnyObject], pageNumber: Int,completionHandler: (result:[String:AnyObject]?, error: NSError?) -> Void) {
        
        // Add page to method parameters
        var withPageDictionary = methodArguments
        withPageDictionary[FlickrClient.ParameterKeys.pageNumber] = pageNumber
        withPageDictionary[FlickrClient.ParameterKeys.photosPerPage] = FlickrClient.Constant.photosPerPage
        
        // Call general get method to call webAPI
        
        taskForGETMethod(withPageDictionary) { JSONResult, error in
            
            // Send required values to completion handler
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let photosDictionary = JSONResult.valueForKey(JSONResponseKeys.Photos) as? [String:AnyObject] {
                    completionHandler(result: photosDictionary, error: nil)
                } else {
                     completionHandler(result: nil, error: NSError(domain: "getImageFromFlickrByLatLonWithPage Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "could not parse getImageFromFlickrByLatLonWithPage"]))
                }
            }
        }
    }
    
    func getFlickrImagesByLatLon(latitude:Double,longitude:Double, nextPageNumber: Int, completionHandler: (result: [[String:AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //Specify parameters
        let dictparameters = [
            FlickrClient.ParameterKeys.Method: FlickrClient.Methods.SearchPhotosbyLatLon,
            FlickrClient.ParameterKeys.ApiKey: FlickrClient.Constant.ApiKey,
            FlickrClient.ParameterKeys.Latitude: latitude,
            FlickrClient.ParameterKeys.Longitude: longitude,
            FlickrClient.ParameterKeys.Safesearch: FlickrClient.Constant.Safesearch,
            FlickrClient.ParameterKeys.Extras: FlickrClient.Constant.Extras,
            FlickrClient.ParameterKeys.Dataformat: FlickrClient.Constant.DataFormat,
            FlickrClient.ParameterKeys.NOJSONCallback: FlickrClient.Constant.No_JSON_CALLBACK
        ]
        
        //Make the request
     let task =   taskForGETMethod(dictparameters as! [String : AnyObject]) { JSONResult, error in
        
        // Send required values to completion handler
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                
                if let photosDictionary = JSONResult.valueForKey(JSONResponseKeys.Photos) as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary[JSONResponseKeys.TotalPages] as? Int {
                     
                        // Pass next page number to flickr API to get the images for different pages
                        println("Total pages are : \(totalPages)")
                        println("Page number is : \(nextPageNumber)")
                        
                        if nextPageNumber <= totalPages {
                            
                            self.getImageFromFlickrByLatLonWithPage(dictparameters as! [String : AnyObject], pageNumber: nextPageNumber) {
                                results, error in
                                
                                if let receivedDictionary = results as [String:AnyObject]? {
                                    
                                    // Received photos array
                                    if let photosArray = receivedDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] {
                                        completionHandler(result: photosArray, error: nil)
                                    }
                                }
                            }
                        } else {
                             completionHandler(result: nil, error: NSError(domain: "VIRTUAL_TOURIST_MESSAGE", code: 101, userInfo: [NSLocalizedDescriptionKey: "There is no more Flickr images available for this location."]))
                        }
                    }
                } else {
                    
                    completionHandler(result: nil, error: NSError(domain: "getFlickrImagesByLatLon Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "could not parse getFlickrImagesByLatLon"]))
                }
            }
        }
        return task
    }
    
    /// Data task to download Flickr image
    func taskForImage(filePath:String, completionHandler :(imageDate:NSData?, error:NSError?) -> Void)-> NSURLSessionTask {
        
        // Flickr image URL
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        
        // Make the request
        let task = session.dataTaskWithRequest(request) {
            data, response, downloadError in
            
            if let error = downloadError {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(imageDate: data, error: newError)
            } else {
                completionHandler(imageDate: data, error: nil)
            }
        }
        task.resume()
        return task
        
    }
}