//
//  Log.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import os.log

class Log {
    
    static func d(_ text: String, functionName: String = #function, lineNumber: Int = #line) {
        let timestamp = Date().description
        print("\(timestamp) \(functionName):\(lineNumber)  \(text)")
    }
    
    static func e(_ text: String) {
        d("Error: \(text)")
        os_log("%s", log: OSLog.default, type: .error, text)
    }
    
    static func i(_ text: String) {
        d("\(text)")
        os_log("%s", log: OSLog.default, type: .info, text)
    }
}
