//
//  FlickrCoreDataManager.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 11/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import Foundation
import CoreData

/* Flicker client extension to fetch photos object for associated location object */

extension FlickrClient {
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Wrapper method to download new Flickr photo collection based on next Page number
    
    func fetchPhotosForNewAlbumAndSaveToDataContext(location:Location, nextPageNumber:Int, errorHandler: (error: NSError?) -> Void) -> NSURLSessionDataTask {
        return prefetchPhotosForLocationAndSaveToDataContext(location, nextPageNumber: nextPageNumber, errorHandler: errorHandler)
    }
    
    // Pre-fetch Flickt photo collection
    
    func prefetchPhotosForLocationAndSaveToDataContext(location:Location , nextPageNumber:Int? = nil, errorHandler: (error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        // Set the page number
        var newPageNumber = nextPageNumber == nil ? 1 : nextPageNumber!
        
        // Create the task
        let task =  FlickrClient.sharedInstance().getFlickrImagesByLatLon(location.latitude, longitude: location.longitude, nextPageNumber: newPageNumber) {
            
            photosDict, error in
            
            // Handle error using Closure
            if let errorMessage = error {
                
                errorHandler(error: errorMessage)
                
            } else {
                
                if let photosArrayDictionary = photosDict as [[String : AnyObject]]? {
                    
                    println("Total number of photos are : \(photosArrayDictionary.count)")
                    
                    //Parse the array of PhotosArrayDictionary
                    var photos = photosArrayDictionary.map() {
                        (dictionary: [String:AnyObject]) -> Photo in
                        var newDictionary = dictionary
                        newDictionary["pageNumber"] = newPageNumber
                        
                        let photoToBeAdded = Photo(dictionary: newDictionary, context: self.sharedContext)
                        photoToBeAdded.location = location
                        return photoToBeAdded
                    }
                }

            }
    }
        
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
        return task
    }
}