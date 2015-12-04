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

    func showActivity() {
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityView?.center = CGPointMake(self.frame.width / 2, self.frame.height / 2)
        activityView?.color = UIColor.whiteColor()
        activityView?.startAnimating()
        imageView.addSubview(activityView!)
    }
}
