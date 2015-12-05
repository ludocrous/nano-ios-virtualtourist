//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Derek Crous on 03/12/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
  
    @IBOutlet weak var imageView: UIImageView!
    
    var activityView : UIActivityIndicatorView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let activityView = activityView {
            if activityView.isAnimating() {
                activityView.stopAnimating()
            }
        }
    }
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        // Mechanism to ensure that we don't have hanging tasks if screen is scrolled away from cell still waiting for image
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    // Show activity spinner while waiting
    func showActivity() {
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityView?.center = CGPointMake(self.frame.width / 2, self.frame.height / 2)
        activityView?.color = UIColor.whiteColor()
        activityView?.startAnimating()
        imageView.addSubview(activityView!)
    }
    
    //Stop Activity spinner
    func stopActivity() {
        if let activityView = activityView {
            activityView.stopAnimating()
            activityView.removeFromSuperview()
        }
    }
}
