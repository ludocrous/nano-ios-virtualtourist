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

    struct Keys {
        static let ID = "id"
        static let Title = "title"
        static let ImagePath = "url_m"
    }

    
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary[Keys.ID] as? String
        title = dictionary[Keys.Title] as? String
        imagePath = dictionary[Keys.ImagePath] as? String
    }
    
    var image: UIImage? {
        
        get {
            return FlClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }

    
}