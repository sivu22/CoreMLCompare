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
    
    static func getFiles(withExtension ext: String, inPath path: String) -> [String]? {
        guard ext.count > 1 && path.count > 1 else {
            Log.e("Invalid parameters extension \(ext) path \(path)")
            return nil
        }
        
        var files: [String] = []
        if let enumerator = FileManager.default.enumerator(atPath: path) {
            while let file = enumerator.nextObject() as? URL {
                if file.pathExtension == ext {
                    files.append(file.lastPathComponent)
                    Log.d("Found compiled model \(files[files.count - 1])")
                }
            }
        }
        
        return files.count > 0 ? files : nil
    }
}

extension Float {
    
    func stringWithTwoDecimals() -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}
