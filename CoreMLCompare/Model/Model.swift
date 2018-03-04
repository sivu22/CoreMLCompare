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
    
    init() {
        state = .none
        name = ""
    }
    
    init(withCoreMLModel model: MLModel, andName givenName: String = "NoName") {
        name = givenName
        
        visionModel = try? VNCoreMLModel(for: model)
        if visionModel == nil {
            Log.e("Failed to init MobileNet model")
            state = .none
        } else {
            state = .loaded
        }
    }
}
