//
//  Location.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 09/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import Foundation
import CoreData

class Location: NSManagedObject {

   // Core data object attributes
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    // Keys to convert dictionary into object
    struct Keys {
        static let Title = "title"
        static let Subtitle = "subtitle"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
    }
    
    // Init method to insert object in core data 
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Init method that will convert  dictionary into managed object and insert in core data
    
    init(dictionary:[String:AnyObject], context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        title = dictionary[Keys.Title] as! String
        subtitle = dictionary[Keys.Subtitle] as! String
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        
    }

}
