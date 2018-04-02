//
//  CMLCError.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 03.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

enum CMLCError: String, Error {
    case avCaptureDevice = "Failed to get default video device"
    case avDeviceInput = "Failed to capture video device input"
    case modelBadURL = "Missing model's URL"
    case fileExist = "File not found"
    case fileSave = "Move file error"
    case fileDelete = "Failed to delete file"
    case downloadFail = "Download failed"
    case addModelFail = "Adding model failed"
    
    func createAlert() -> UIAlertController {
        return CMLCError.createAlert(withText: rawValue)
    }
    
    static func createAlert(withText text: String, andTitle title: String = "Error") -> UIAlertController {
        let alert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(defaultAction)
        
        Log.e(text)
        return alert
    }
}
