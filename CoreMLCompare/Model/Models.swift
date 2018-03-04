//
//  Models.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import Vision

struct Models {
    
    private(set) var cmlcModels = [Model]()
    let count = 4
    
    init() {
        // Load the reference model by default
        let model = Model(withCoreMLModel: MobileNet().model, andName: "MobileNet")
        cmlcModels.append(model)
        
        if model.state == .loaded {
            Log.i("Successfully loaded model \(model.name)")
        }
    }
    
    func modelAtIndex(_ index: Int) -> Model? {
        guard index < count else {
            return nil
        }
        
        return cmlcModels[index]
    }
    
    func visionModelAtIndex(_ index: Int) -> VNCoreMLModel? {
        guard index < count else {
            return nil
        }
        
        return cmlcModels[index].visionModel
    }
    
    mutating func loadModels() -> String? {
        var error: String?
        
        let model2URL = Bundle.main.url(forResource: "SqueezeNet", withExtension: "cmlc")
        var model2: Model?
        if let compiledModelURL = try? MLModel.compileModel(at: model2URL!) {
            if let compiledModel = try? MLModel(contentsOf: compiledModelURL) {
                model2 = Model(withCoreMLModel: compiledModel, andName: "SqueezeNet")
            } else {
                Log.e("Failed to read SqueezeNet model")
            }
        } else {
            Log.e("Failed to compile model SqueezeNet")
        }
        
        if let model2 = model2 {
            if model2.state == .loaded {
                Log.i("Successfully loaded model \(model2.name)")
                cmlcModels.append(model2)
            } else {
                Log.e("Failed to init SqueezeNet model")
                error! += "Failed to init SqueezeNet model"
            }
        }
        
        return error
    }
}
