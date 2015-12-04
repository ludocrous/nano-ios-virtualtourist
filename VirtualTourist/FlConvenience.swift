//
//  FlConvenience.swift
//  VirtualTourist
//
//  Created by Derek Crous on 30/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import Foundation


extension FlClient {
    
    func getCollectionAroundPin(pin : Pin) {
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
            "per_page": "21"
        ]
        getImageFromFlickrBySearch(methodArguments)
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
}