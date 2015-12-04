//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Derek Crous on 28/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    
    var inEditMode : Bool = false
    
    @IBAction func doSomething(sender: UIBarButtonItem) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        restoreMapRegion(false)
        setUpViewForState()
        setAnnotationsFromPins()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    

    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()

    func setUpViewForState() {
        if inEditMode {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }

    @IBAction func mapPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let touchLocation : CGPoint = sender.locationInView(mapView)
            let coordinate : CLLocationCoordinate2D = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            createPinAtCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
    
    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        inEditMode = !inEditMode
        setUpViewForState()
    }
    
    
    func createPinAtCoordinates(latitude latitude: Double, longitude: Double) {
        let pin = Pin(latitude: latitude, longitude: longitude, context: sharedContext)
        mapView.addAnnotation(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func setAnnotationsFromPins() {
        do {
            try fetchedResultsController.performFetch()
            if let results = fetchedResultsController.fetchedObjects {
                for pin in results {
                    mapView.addAnnotation(pin as! Pin)
                }
            }
        } catch {}
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCollection" {
            if let collectionViewController = segue.destinationViewController as? CollectionViewController {
                collectionViewController.pin = sender as! Pin
            }
        }
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let pin = view.annotation {
            if inEditMode {
                mapView.removeAnnotation(pin)
                sharedContext.deleteObject(pin as! NSManagedObject)
                CoreDataStackManager.sharedInstance().saveContext()
            } else {
                self.performSegueWithIdentifier("showCollection", sender: pin)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            app.openURL(NSURL(string: annotationView.annotation!.subtitle!!)!)
        }
    }


    //MARK - Persist map position functions
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    

}

