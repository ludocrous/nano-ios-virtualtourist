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

class CollectionViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImageView: UIView!
    @IBOutlet weak var collectionButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.delegate = self
        collectionView.dataSource = self

        setupMapView()
        noImageView.hidden = true
        loadCollectionForPin()
    }
    
    @IBAction func collectionButtonPressed(sender: UIBarButtonItem) {
    }
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
        
        return fetchedResultsController
        
    }()
    


    func setupMapView() {
        mapView.centerCoordinate = pin.coordinate
        mapView.addAnnotation(pin)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let savedRegion = MKCoordinateRegion(center: pin.coordinate, span: span)
        mapView.setRegion(savedRegion, animated: false)

    }
    
    func loadCollectionForPin() {
        if pin.photos.isEmpty {
            dbg("Photos array is empty, fetching from Flickr")
            FlClient.sharedInstance().getCollectionAroundPin(pin) { (success, errorString) -> Void in
                if success {
                    do {
                        try self.fetchedResultsController.performFetch()
                        CoreDataStackManager.sharedInstance().saveContext()
                        dispatch_async(dispatch_get_main_queue(), {
                            self.collectionView.reloadData()
                        })
                    } catch {}
                } else {
                    dbg("Oh Oh")
                }
            }
        } else {
            do {
                try self.fetchedResultsController.performFetch()
                dbg("Performing fetch")
            } catch {}
        }
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath : NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let localImage = photo.image {
            cell.imageView.image = localImage
        } else if photo.imagePath == nil || photo.imagePath == "" {
            cell.imageView.image = UIImage(named: "noImage")
        } else {
            cell.showActivity()
            dbg("Fetching image from Flickr: \(photo.imagePath)")
            let task = FlClient.sharedInstance().getFlickrPhotoImage(photo.imagePath!) { (imageData, error) -> Void in
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        photo.image = image
                        cell.imageView.image = image
                        cell.stopActivity()
                    }
                }
            }
            cell.taskToCancelifCellIsReused = task
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
    
    //MARK: Collection view methods
    
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
}
