//
//  LCUtils.swift
//  OnTheMap
//
//  Created by Derek Crous on 06/10/2015.
//  Copyright © 2015 Ludocrous Software. All rights reserved.
//

import UIKit


let DEBUG_PRINT = true
let ERROR_PRINT = true

//Debug and Error statements used to replace generic print statements in code
//Used for debug statements
func dbg(toPrint : AnyObject) {
    if DEBUG_PRINT {
        print("Dbg:\(toPrint)")
    }
}

//Used for error statements
func err(printString : String) {
    if ERROR_PRINT {
        print("Dbg:\(printString)")
    }
}


func displayAlert(title: String, message: String?, onViewController: UIViewController) {
    let myAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    myAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
    onViewController.presentViewController(myAlert,animated: true, completion: nil)
}

func displayAlertOnMainThread(title: String, message: String?, onViewController: UIViewController) {
    dispatch_async(dispatch_get_main_queue(),{
        displayAlert( title, message: message, onViewController: onViewController)
    })
}


func daysBetweenDates(startDate: NSDate, endDate: NSDate) -> Int
{
    let calendar = NSCalendar.currentCalendar()
    let components = calendar.components([.Day], fromDate: startDate, toDate: endDate, options: [])
    return components.day
}
