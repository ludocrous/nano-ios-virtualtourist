//
//  FlClient.swift
//  VirtualTourist
//
//  Created by Derek Crous on 29/11/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import Foundation

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = FLICKER_API_KEY // This is set in file secret.swift
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"


class FlClient : NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    
    var session : NSURLSession
    
    var sessionID: String? = nil
    var userID: String? = nil
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    
        func getFlickrPhotosBySearch(forPin pin: Pin, methodArguments: [String : AnyObject], completionHandler: (success: Bool, errorString: String?) -> Void) -> NSURLSessionTask {
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                err("There was an error with your request: \(error)")
                completionHandler(success: false, errorString: error?.localizedDescription)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    err("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    err("Your request returned an invalid response! Response: \(response)!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response! Response: \(response)!")
                } else {
                    err("Your request returned an invalid response!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                err("No data was returned by the request!")
                completionHandler(success: false, errorString: "No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                err("Could not parse the data as JSON: '\(data)'")
                completionHandler(success: false, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                err("Flickr API returned an error. See error code and message in \(parsedResult)")
                completionHandler(success: false, errorString: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                err("Cannot find keys 'photos' in \(parsedResult)")
                completionHandler(success: false, errorString: "Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                err("Cannot find key 'pages' in \(photosDictionary)")
                completionHandler(success: false, errorString: "Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            /* Pick a random page! */
            let pageLimit = min(totalPages, 40)
            let randomPage = 1 // Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getFlickrPhotosBySearchWithPage(forPin: pin, methodArguments: methodArguments, pageNumber: randomPage, completionHandler: completionHandler)
        }
        
        task.resume()
        return task
    }

    func getFlickrPhotosBySearchWithPage(forPin pin: Pin, methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                err("There was an error with your request: \(error)")
                completionHandler(success: false, errorString: error?.localizedDescription)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    err("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    err("Your request returned an invalid response! Response: \(response)!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response! Response: \(response)!")
                } else {
                    err("Your request returned an invalid response!")
                    completionHandler(success: false, errorString: "Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                err("No data was returned by the request!")
                completionHandler(success: false, errorString: "No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                err("Could not parse the data as JSON: '\(data)'")
                completionHandler(success: false, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                err("Flickr API returned an error. See error code and message in \(parsedResult)")
                completionHandler(success: false, errorString: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                err("Cannot find key 'photos' in \(parsedResult)")
                completionHandler(success: false, errorString: "Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                err("Cannot find key 'total' in \(photosDictionary)")
                completionHandler(success: false, errorString: "Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    err("Cannot find key 'photo' in \(photosDictionary)")
                    completionHandler(success: false, errorString: "Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                for photo in photosArray {
                    let photoDictionary = photo as [String: AnyObject]
                    dbg(photoDictionary)
//                    let id = photoDictionary["id"] as? Int64
//                    let title = photoDictionary["title"] as? String
//                    let imagePath = photoDictionary["url_m"] as? String
                    let newPhoto = Photo(dictionary: photoDictionary, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                    newPhoto.pin = pin
                }
                completionHandler (success: true, errorString: nil)
                
//               let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                
//                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                
//                let photoTitle = photoDictionary["title"] as? String /* non-fatal */
                
                /* GUARD: Does our photo have a key for 'url_m'? */
//                guard let imageUrlString = photoDictionary["url_m"] as? String else {
//                    err("Cannot find key 'url_m' in \(photoDictionary)")
//                    return
//                }
//
//                let imageURL = NSURL(string: imageUrlString)
//                if let imageData = NSData(contentsOfURL: imageURL!) {
//                    dispatch_async(dispatch_get_main_queue(), {
//                        
//                        self.setUIEnabled(enabled: true)
//                        self.defaultLabel.alpha = 0.0
//                        self.photoImageView.image = UIImage(data: imageData)
//                        
//                        if methodArguments["bbox"] != nil {
//                            if let photoTitle = photoTitle {
//                                self.photoTitleLabel.text = "\(self.getLatLonString()) \(photoTitle)"
//                            } else {
//                                self.photoTitleLabel.text = "\(self.getLatLonString()) (Untitled)"
//                            }
//                        } else {
//                            self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
//                        }
//                    })
//                } else {
//                    dispatch_async(dispatch_get_main_queue(), {
//                        self.setUIEnabled(enabled: true)
//                    })
//                    print("Image does not exist at \(imageURL)")
//                }
//            } else {
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.setUIEnabled(enabled: true)
//                    self.photoTitleLabel.text = "No Photos Found. Search Again."
//                    self.defaultLabel.alpha = 1.0
//                    self.photoImageView.image = nil
//                })
            }
        }
        
        task.resume()
    }
    
    
    func getFlickrPhotoImage(imagePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: imagePath)!
//        let url = baseURL.URLByAppendingPathComponent(size).URLByAppendingPathComponent(filePath)
        
        print(url)
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }


    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    
    //MARK: Singleton of class
    
    class func sharedInstance() -> FlClient {
        
        struct Singleton {
            static var sharedInstance = FlClient()
        }
        
        return Singleton.sharedInstance
    }
    
}
