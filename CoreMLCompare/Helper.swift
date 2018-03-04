//
//  Helper.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation

class Helper {
    
    static private(set) var supportPath: String = {
        let fileManager = FileManager.default
        let URLs = fileManager.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: .userDomainMask)
        
        Log.d("supportPath = " + URLs[0].path)
        return URLs[0].path
    }()
}
