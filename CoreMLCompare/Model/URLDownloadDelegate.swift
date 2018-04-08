//
//  URLDownloadDelegate.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 08.04.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation

protocol URLDownloadDelegate: class {
    
    // Will be called on the main thread
    func reportProgress(_ percentage: Int, atIndex index: IndexPath)
}
