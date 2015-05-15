//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 10/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource,UICollectionViewDelegate,NSFetchedResultsControllerDelegate {
  
    // Location object for which Flickr images are displayed in collection view
    var location:Location!
    
    // Track index paths for Selection, Insertion, Update and Deletion of images
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // Datatask to fetch images for new collection
    var dataTask: NSURLSessionDataTask?
    
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newPhotoCollectionButton: UIBarButtonItem!
    @IBOutlet weak var dataDownloadActivityIndicator: UIActivityIndicatorView!
    
    var sharedContext: NSManagedObjectContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    //MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.hidden = false
        self.navigationController?.navigationItem.hidesBackButton = false
        self.navigationController?.toolbarHidden = false
        
        //Display the annotation for location
        setMapRegionAndAddAnnotation(true)
        
        dataDownloadActivityIndicator.startAnimating()
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        fetchedResultsController.delegate = self
        
        // Tool bar button to toggle New collection and Save collection button
        updateToolbarButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // This is called rarely - as Flickr photos are already fetched when pin is dropped on the map in previous view controller
        if location.photos.isEmpty {
            var currentPageNumber = 0
            loadNewCollection(currentPageNumber)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove the delegate reference
        fetchedResultsController.delegate = nil
        
        // Stop all the downloading tasks
        if dataTask?.state == NSURLSessionTaskState.Running {
            dataTask?.cancel()
        }
    }
    
    //Layout collection view
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width, with space
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(photoCollectionView.frame.width / 3)
        layout.itemSize = CGSize(width: width, height: width)
        photoCollectionView.collectionViewLayout = layout
    }
    
    //MARK: - Map region
    func setMapRegionAndAddAnnotation(animated: Bool) {
            let longitude = location.longitude
            let latitude = location.latitude
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
            let longitudeDelta = 4.0
            let latitudeDelta = 4.0
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
            let region = MKCoordinateRegion(center: center, span: span)
           locationMapView.setRegion(region, animated: animated)
        
        // Show the annotation for the location
       let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = center
        newAnnotation.title = location.title
        newAnnotation.subtitle = location.subtitle
        locationMapView.addAnnotation(newAnnotation)
    }
    
    //MARK:- UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCollectionCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
      
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // This method will download the image and display as soon  as the imgae is downloaded
    func configureCell(cell:PhotoCollectionViewCell, atIndexPath indexPath:NSIndexPath) {
       
        dataDownloadActivityIndicator.stopAnimating()
        
        // Show the placeholder image till the time image is being downloaded
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        var cellImage = UIImage(named: "imagePlaceholder")
        cell.photoImage.image = nil
        
        // Set the flickr image if already available (from hard disk or image cache)
        if photo.image != nil {
            cellImage = photo.image
        } else {
            
            //If image is not available, download the flickr image
            //Start the task that will eventually download the image
            
            cell.photoDownloadActivityIndicator.startAnimating()
            
            let task = FlickrClient.sharedInstance().taskForImage(photo.imageUrl) {
                data, error in
                if let downloaderror = error {
                    print("Flick image download error: \(downloaderror.localizedDescription)")
                    cell.photoDownloadActivityIndicator.stopAnimating()
                }
                if let imageData = data {
                    
                    // Create the image
                    let image = UIImage(data: imageData)
                    
                    // Update the model so that information gets cached
                    photo.image = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                       
                        photo.downloadStatus = true
                        cell.photoImage.image = image
                        cell.photoDownloadActivityIndicator.stopAnimating()
                        
                        // Update the state of the image that it is downloaded
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                        self.updateToolbarButton()
                    }
                } else {
                    println("Data is not convertible to Image Data.")
                    cell.photoDownloadActivityIndicator.stopAnimating()
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.photoImage.image = cellImage
        
        //If the cell is selected, it will show delete button
        if let index = find(selectedIndexes, indexPath) {
            cell.deleteButton.hidden = false
            cell.photoImage.alpha = 0.5
        } else {
            cell.deleteButton.hidden = true
            cell.photoImage.alpha = 1.0
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        //Toggle the cell's presence in SelectedItems array when cell is tapped
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        //Then configure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // Update toolbar button
        updateToolbarButton()
    }
    
    
    
    //MARK:- Core Data
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
      let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location)
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchResultController
    }()
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    // Insert, Update and delete collection view cells when objects are inserted, updated and deleted
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            println("Item added")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Update:
           println("Item updated")
            updatedIndexPaths.append(indexPath!)
            break
        case .Delete:
           println("Item deleted")
            deletedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent changes count: \(deletedIndexPaths.count) \(insertedIndexPaths.count)")
        
        photoCollectionView.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    //MARK:- Toolbar button states and actions
    
    func updateToolbarButton() {
        if selectedIndexes.count > 0 {
            newPhotoCollectionButton.tintColor = UIColor.redColor()
            newPhotoCollectionButton.title = "Save Collection"
            
        } else {
            newPhotoCollectionButton.tintColor = UIColor(red: 217/255, green: 83/255, blue: 117/255, alpha: 1.0)
            newPhotoCollectionButton.title = "New Collection"
            enableButtonForNewCollectionButton()
        }
    }
    
    // Enable new collection button only when all images are downloaded
    func enableButtonForNewCollectionButton() {
        
        let photosCollection = fetchedResultsController.fetchedObjects as! [Photo]
        let photosToBeDownloaded  =   photosCollection.filter {
            $0.downloadStatus == false
        }
        if photosToBeDownloaded.count > 0 {
            newPhotoCollectionButton.enabled = false
        } else {
            newPhotoCollectionButton.enabled = true
        }
        
    }
    
    @IBAction func toolbarButtonClick(sender: UIBarButtonItem) {
        if !selectedIndexes.isEmpty {
            deleteSelectedPhotos()
        } else {
            deleteAllPhotosAndCreateNewCollection()
            newPhotoCollectionButton.enabled = false
        }
    }
    
    func  deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        selectedIndexes = [NSIndexPath]()
        updateToolbarButton()
    }
    
    func deleteAllPhotosAndCreateNewCollection() {
        var currentPageNumber : Int = 0
        dataDownloadActivityIndicator.startAnimating()
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
           currentPageNumber = photo.pageNumber as Int
            sharedContext.deleteObject(photo)
        }
         CoreDataStackManager.sharedInstance().saveContext()
        loadNewCollection(currentPageNumber)
    }
    
    //Locad new flickr image collection by taking into account next page number
    func loadNewCollection(currentPageNumber: Int) {
        dataTask = FlickrClient.sharedInstance().fetchPhotosForNewAlbumAndSaveToDataContext(location , nextPageNumber: currentPageNumber + 1) {
            error in
            if let errorMessage = error {
                dispatch_async(dispatch_get_main_queue()) {
                    var alert =  UIAlertController(title: "Search Error", message: errorMessage.localizedDescription, preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: {
                    self.dataDownloadActivityIndicator.stopAnimating()
                    })
                }
            }
        }
    }
  
    
}
