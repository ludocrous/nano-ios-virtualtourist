//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class CollectionViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    var pinHasImages: Bool = false
    var imagesToBeLoaded: Int = 0
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImageView: UIView!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionToolbar: UIToolbar!
    
    
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    //MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.delegate = self
        collectionView.dataSource = self
        pinHasImages = false
        collectionToolbar.userInteractionEnabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setupMapView()
        loadCollectionForPin()
        fetchResults()
    }
    
    //MARK: Properties
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = []//NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        
    }()
    
    //MARK: Utility functions
    func fetchResults() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            err("Error performing fetch results")
        }
    }
    

    // Set the mini map view to show the pin in question.
    func setupMapView() {
        mapView.centerCoordinate = pin.coordinate
        mapView.addAnnotation(pin)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let savedRegion = MKCoordinateRegion(center: pin.coordinate, span: span)
        mapView.setRegion(savedRegion, animated: false)

    }
    
    //function to control the display whether or not the pin has photos associated with it
    func setupView() {
            noImageView.hidden = pinHasImages
            noImageLabel.hidden = pinHasImages
            updateCollectionButton()
    }
    
    func updateCollectionButton () {
        //depending on selection status toggle button title
        collectionToolbar.userInteractionEnabled = pinHasImages && (imagesToBeLoaded == 0)
        collectionButton.enabled = pinHasImages && (imagesToBeLoaded == 0)
        if selectedIndexes.count > 0 {
            collectionButton.title = "Remove Selected Pictures"
        } else {
            collectionButton.title = "New Collection"
        }
    }
    

    
    //This function will request a collection of images for the pin associated with the view
    func loadCollectionForPin() {
        //If photo array has elements then no need to load as they are already in local storage
        if pin.photos.isEmpty {
            dbg("Photos array is empty, fetching from Flickr")
            collectionButton.enabled = false
            FlClient.sharedInstance().getCollectionAroundPin(pin) { (success, errorString) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        // TODO: This is a lot to push to main thread, Check thread safety of various coredata functions
                        self.fetchResults()
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.pinHasImages = true
                        self.setupView()
                        self.collectionView.reloadData()
                        self.collectionButton.enabled = true
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.pinHasImages = false
                        self.setupView()
                        self.collectionButton.enabled = true
                    })
                }
            }
        } else {
            pinHasImages = true
            setupView()
            fetchResults()
        }
    }
    
    func deleteCollection () {
        // On clicking New Collection delete all associated photo objects from the context.
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for photo in fetchedObjects {
                sharedContext.deleteObject(photo as! NSManagedObject)
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func deletePhotosFromCollection() {
        //Delete only selected photo objects from the context.
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        //Clear the selected indexs array
        selectedIndexes = [NSIndexPath]()
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath : NSIndexPath) {
        // This function will determine what to display based on the state of network queries
        dbg("Request for cell: \(indexPath)")
        if let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            //If a photo object exists then see if it already has its image property set and use that
            if let localImage = photo.image {
                cell.imageView.image = localImage
            } else if photo.imagePath == nil || photo.imagePath == "" {
                // If image is not set and no hope of getting an image then set No Image"
                cell.imageView.image = UIImage(named: "noImage")
            } else {
                // Otheriwse place a placeholder and spawn request to get image, showing an activity view while waiting for callback.
                cell.imageView.image = UIImage(named: "placeHolder")
                cell.showActivity()
//                dbg("Fetching image from Flickr: \(photo.imagePath)")
                imagesToBeLoaded++
                updateCollectionButton()
                dbg("image count \(imagesToBeLoaded)")
                let task = FlClient.sharedInstance().getFlickrPhotoImage((photo.imagePath!)) { (imageData, error) -> Void in
                    //irrespective of result, stop activity
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.stopActivity()
                        self.imagesToBeLoaded--
                        dbg("image count \(self.imagesToBeLoaded)")
                        if self.imagesToBeLoaded == 0 {
                            self.updateCollectionButton()
                        }

                    }
                    //process the image
                    if let data = imageData {
                        dispatch_async(dispatch_get_main_queue()) {
                            let image = UIImage(data: data)
                            photo.image = image
                            cell.imageView.image = image
                        }
                    }
                }
                cell.taskToCancelifCellIsReused = task
            }
            if let _ = selectedIndexes.indexOf(indexPath) {
                cell.imageView.alpha = 0.25
            } else {
                cell.imageView.alpha = 1.0
            }
        } else {
            //Should not get here, other than from unhandled race condition
            err("No photo !!!!!")
        }

    }
    
    @IBAction func collectionButtonPressed(sender: UIBarButtonItem) {
        if selectedIndexes.count > 0 {
            //If in selection mode delete only selected images from collection
            deletePhotosFromCollection()
            fetchResults()
            collectionView.reloadData()
            updateCollectionButton()
        } else {
            //otherwise delete entire collection and request the next one
            deleteCollection()
            loadCollectionForPin()
            fetchResults()
            collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSizeZero
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let width = floor(collectionView.frame.size.width / 3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    //MARK: Collection view delegate methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        let sections = self.fetchedResultsController.sections?.count ?? 0
        dbg("Sections: \(sections)")
        return sections
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        dbg("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo", forIndexPath: indexPath) as! PhotoCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        updateCollectionButton()
    }
   
    
    // MARK: - Fetched Results Controller Delegate Methods
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        dbg("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            dbg("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            dbg("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            dbg("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            dbg("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        dbg("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

}
