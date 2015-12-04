//
//  Photo.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(id: String, imagePath: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.id = id
        self.imagePath = imagePath
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }

    
}