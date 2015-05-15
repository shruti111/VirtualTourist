//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 10/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    //MARK:- Retrieving Images
    
    func imageWithIdentifier(identifier:String?) -> UIImage? {
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // Memory Cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        //if not in Memory cache, then in Hard drive
        if let data = NSData(contentsOfFile: path) {
            let thisImage = UIImage(data: data)
            return UIImage(data: data)
        }
        return nil
        
    }
    
    //MARK: Saving Images
    
    func storeImage(image:UIImage?, withIdentifier identifier:String) {

        let path = pathForIdentifier(identifier)
    
        //If the image is nil, remove images from cache and hard disk
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        //Otherwise keep image in memory
        inMemoryCache.setObject(image!, forKey: path)
        
        // And add in documents directory
        let data = UIImagePNGRepresentation(image!)
    if  data.writeToFile(path, atomically: true) {
            println("***** Data Written to file *****")
        }
    }
    
   
    
    //MARK:- Imagepath based on Id
    
    func pathForIdentifier(identifier:String) -> String {
        let documentsDirectoryURL: NSURL =  NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first! as! NSURL
        
        let fullPathURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        return fullPathURL.path!
    }
    
}
