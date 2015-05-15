//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 08/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var locations = [Location]()
   
    // Geocoder to get the address of the pin
    let geocoder = CLGeocoder()
    
    // Location is updated when pin is dragged from one location to another location
    var locationToUpdate:Location?
    // Pin is updated when pin is dragged from one location to another
    var annotaionToUpdate: MKAnnotation?
    
    // All static varibales used to save data
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
        static let mapFileName = "mapRegionArchive"
        static let pinTitle = "Dropped Pin"
        static let pinSubtitle = "Address Unknown"
        static let pinCellId = "travelLocationPinId"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion(false)
        addGesturesToMapView()
        
        // Fetch all pins from core data and show in the mapview
        locations = fetchAllLocations()
        updateMapViewWithAnnotations()
        
    }
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.hidden = true
        self.navigationController?.toolbarHidden = true
    }
    
    //MARK:- MapView and MapRegion
    
    // Save the mapRegion using NSKeyedArchiver
    
    var mapRegionFilePath: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Keys.mapFileName).path!
    }
    
    func saveMapRegion() {
        let mapRegionDictionary = [
            Keys.Latitude : mapView.region.center.latitude,
            Keys.Longitude : mapView.region.center.longitude,
            Keys.LatitudeDelta : mapView.region.span.latitudeDelta,
            Keys.LongitudeDelta : mapView.region.span.longitudeDelta
        ]
        NSKeyedArchiver.archiveRootObject(mapRegionDictionary, toFile: mapRegionFilePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        if let mapRegionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String:AnyObject] {
            
            let longitude = mapRegionDictionary[Keys.Longitude] as! CLLocationDegrees
            let latitude = mapRegionDictionary[Keys.Latitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = mapRegionDictionary[Keys.LongitudeDelta] as! CLLocationDegrees
            let latitudeDelta = mapRegionDictionary[Keys.LatitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    //Show annotations in Mapview based on saved locations in core data
    
    func updateMapViewWithAnnotations() {
        var annotations = [MKPointAnnotation]()
        if locations.count > 0 {
            for location in locations {
                var annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                annotation.title = location.title
                annotation.subtitle = location.subtitle
                annotations.append(annotation)
            }
        }
        mapView.addAnnotations(annotations)
    }
    
    
    
    //MARK:- Add Pin on touch and hold gesture
    
    func addGesturesToMapView() {
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
      
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            // Get the coordinates at the long press gesture point
            let touchPoint:CGPoint = gestureRecognizer.locationInView(mapView)
           
            // Convert point to coordinate
            let touchPointCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            //Add this location to Map and Core data
            addAnnotation(touchPointCoordinate)
        }
    }
    
    // Add pin annotation after long press gesture
    func addAnnotation(locationPoint:CLLocationCoordinate2D) {
        
        let newLocation: CLLocation = CLLocation(latitude: locationPoint.latitude, longitude:locationPoint.longitude)
        
        var newAnnotation:MKPointAnnotation?
        newAnnotation = MKPointAnnotation()
        newAnnotation!.coordinate = locationPoint
        newAnnotation!.title = Keys.pinTitle
        newAnnotation!.subtitle = Keys.pinSubtitle

        // Get the location Using reverse geocoding - this is used to show sub title of a pin
        geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
            placemark, error in
            
            if error == nil && !placemark.isEmpty {
                if placemark.count > 0 {
                    
                    // Update the annotation subtitle if we get the address
                    let topPlaceMark = placemark.last as! CLPlacemark
                    var annotationSubtitle = self.creareSubtitleFromPlacemark(topPlaceMark)
                    newAnnotation!.subtitle = annotationSubtitle
                }
            }
            
            // Add to mapView
            self.mapView.addAnnotation(newAnnotation!)
            
            dispatch_async(dispatch_get_main_queue()) {
                
                // Add this annotation point to core data as Location object
                self.addMapLocation(newAnnotation!)
                if self.locationToUpdate != nil  {
                    self.removeMapLocation()
                }
            }

        })
    }
    //Helper method to create address from placemark object
    func creareSubtitleFromPlacemark(placemark:CLPlacemark) -> String {
        var addressComponents = [String]()
        
        addressComponents = appendComponentIfNotNil(placemark.inlandWater, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.ocean, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.subThoroughfare, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.thoroughfare, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.locality, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.administrativeArea, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.postalCode, addressComponents: addressComponents)
        addressComponents = appendComponentIfNotNil(placemark.country, addressComponents: addressComponents)
        
        if addressComponents.isEmpty {
            return Keys.pinSubtitle
        }
        var completeAddress = join(", ", addressComponents)
        return completeAddress
    }
    
    func appendComponentIfNotNil(addressComponent:String?, var addressComponents :[String]) -> [String] {
        if let component = addressComponent {
            addressComponents.append(component)
        }
        return addressComponents
    }

    
    //MARK:- Core Data Operations
    
    var sharedContext: NSManagedObjectContext {
       return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func fetchAllLocations() -> [Location] {
        var error:NSError? = nil
        
        //Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Location")
       
            let results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
            if error != nil {
                println("Error in fetchAllLocations")
            
        }
        
        return results as! [Location]
    }
    
    func addMapLocation(annotation:MKAnnotation) {
        let locationDictionary: [String : AnyObject] = [
            Location.Keys.Latitude : annotation.coordinate.latitude,
            Location.Keys.Longitude : annotation.coordinate.longitude,
            Location.Keys.Title: annotation.title!,
            Location.Keys.Subtitle: annotation.subtitle!
        ]
        let locationToBeAdded = Location(dictionary: locationDictionary, context: sharedContext)
        self.locations.append(locationToBeAdded)
        CoreDataStackManager.sharedInstance().saveContext()
        
        //Pre-Fetch photos entites related to this location and save to core data
        
        FlickrClient.sharedInstance().prefetchPhotosForLocationAndSaveToDataContext(locationToBeAdded) {
            error in 
            if let errorMessage = error {
                println(errorMessage.localizedDescription)
            }
        }
        
    }
    
    func removeMapLocation() -> Void {
        
        // Remove annotation
        self.mapView.removeAnnotation(self.annotaionToUpdate)
        
        if let locationToDelete = locationToUpdate {
            
            //Remove location from array
            let index = (self.locations as NSArray).indexOfObject(locationToDelete)
            self.locations.removeAtIndex(index)
            
            //Remove location from context
            sharedContext.deleteObject(locationToDelete)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        locationToUpdate = nil
        annotaionToUpdate = nil
    }
    
    func getMapLocationFromAnnotation(annotation:MKAnnotation) -> Location? {
        
        // Fetch exact map location from annotation view
        let filteredLocations =   self.locations.filter {
            $0.title == annotation.title &&
                $0.subtitle == annotation.subtitle &&
                $0.latitude == annotation.coordinate.latitude &&
                $0.longitude == annotation.coordinate.longitude
        }
        if filteredLocations.count > 0 {
            return filteredLocations.last!
        }
        return nil
    }
    
    //MARK:- Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let annotaionView = sender as? MKAnnotationView {
            let controller = segue.destinationViewController as! PhotoAlbumViewController
            controller.location = getMapLocationFromAnnotation(annotaionView.annotation)
        }
    }    
}

extension TravelLocationsMapViewController:MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reusableMapId = Keys.pinCellId
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reusableMapId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusableMapId)
            pinView!.draggable = true
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
            pinView!.pinColor = MKPinAnnotationColor.Purple
            
            //Right call out button to display Flickr images
            pinView!.rightCalloutAccessoryView =  UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            
            //  Left call out button as delte pin button
            let deleteLocationButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            deleteLocationButton.frame = CGRectMake(0, 0, 20, 20)
            deleteLocationButton.setImage(UIImage(named: "deleteLocation"), forState: UIControlState.Normal)
           pinView?.leftCalloutAccessoryView = deleteLocationButton
            
            
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Update location when pin is dragged
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if oldState == MKAnnotationViewDragState.Starting {
            // get location object from existing annotation
            locationToUpdate = getMapLocationFromAnnotation(view.annotation)
            annotaionToUpdate = view.annotation
        }
        
        if newState == MKAnnotationViewDragState.Ending {
            // Update Pin
            addAnnotation(view.annotation.coordinate)
            
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        if control == view.rightCalloutAccessoryView {
            // Show flickr images on right call out
            performSegueWithIdentifier("showAlbum", sender: view)
            
        } else if control == view.leftCalloutAccessoryView {
            
             // Delete annotation and location on left call out
             locationToUpdate = getMapLocationFromAnnotation(view.annotation)
            annotaionToUpdate = view.annotation
            removeMapLocation()
        }
    }
    
}

