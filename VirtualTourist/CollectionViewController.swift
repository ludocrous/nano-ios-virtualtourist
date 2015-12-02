//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit
import MapKit

class CollectionViewController : UIViewController {
    
    var pin: Pin!
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupMapView()
    }

    func setupMapView() {
        mapView.centerCoordinate = pin.coordinate
        mapView.addAnnotation(pin)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let savedRegion = MKCoordinateRegion(center: pin.coordinate, span: span)
        mapView.setRegion(savedRegion, animated: false)

    }
    
    func loadCollectionForPin() {
        FlClient.sharedInstance().getCollectionAroundPin(pin) 
        
    }

}
