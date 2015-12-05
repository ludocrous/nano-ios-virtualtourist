//
//  Pin.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import Foundation
import MapKit
import CoreData

//MARK: Constants

let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0


class Pin : NSManagedObject, MKAnnotation { // Follow MKAnnotation protocol to enable direct placement on map.
    @NSManaged var latitude : Double
    @NSManaged var longitude : Double
    @NSManaged var pageForCollection: Int
    @NSManaged var photos : [Photo]
    
    //CoreData compliance
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init (latitude : Double, longitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.pageForCollection = 0
    }
    
    //Return coordinates for map/annotation interaction
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func boundingBoxString() -> String {
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    deinit {
        dbg("Pin being destroyed")
    }
}