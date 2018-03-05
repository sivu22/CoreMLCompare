//
//  Model.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import Vision

struct Model {
    
    enum State {
        case none
        case loaded
        case enabled
    }
    
    private(set) var visionModel: VNCoreMLModel?
    private(set) var name: String
    private(set) var state: State
    
    private(set) var object: String
    private(set) var confidence: String
    
    init() {
        state = .none
        name = ""
        
        object = ""
        confidence = "0%"
    }
    
    init(withCoreMLModel model: MLModel, andName givenName: String = "NoName") {
        name = givenName
        
        object = ""
        confidence = "0%"
        
        visionModel = try? VNCoreMLModel(for: model)
        if visionModel == nil {
            Log.e("Failed to init MobileNet model")
            state = .none
        } else {
            state = .loaded
        }
    }
    
    mutating func objectClassified(_ result: VNClassificationObservation) -> Bool {
        if result.confidence > 0.5 {
            object = result.identifier.localizedCapitalized
            confidence = (result.confidence * 100).stringWithTwoDecimals() + "%"
            
            return true
        }
        
        return false
    }
}
