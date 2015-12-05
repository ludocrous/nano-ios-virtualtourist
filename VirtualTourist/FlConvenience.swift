//
//  FlConvenience.swift
//  VirtualTourist
//
//  Created by Derek Crous on 30/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import Foundation


extension FlClient {
    
    // First step in querying the Flickr api
    func getCollectionAroundPin(pin : Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
//            "bbox": pin.boundingBoxString(),
            "lat": "\(pin.latitude)",
            "lon": "\(pin.longitude)",
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": "\(PER_PAGE)"
        ]
        getFlickrPhotosBySearch(forPin: pin, methodArguments: methodArguments, completionHandler: completionHandler)
    }
    
    // Cache to store local copies of image data for collections after first loading.
    struct Caches {
        static let imageCache = ImageCache()
    }
    
}