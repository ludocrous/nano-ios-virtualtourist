//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit
import MapKit

class CollectionViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.delegate = self
        collectionView.dataSource = self
//        let width = CGRectGetWidth(collectionView!.frame) / 3
//        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
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
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 21
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo", forIndexPath: indexPath) as! PhotoCell
        cell.showActivity()
        return cell
    }
}
