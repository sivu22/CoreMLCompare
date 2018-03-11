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
    
    var cmlcModels = [Model]()
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
        guard index < count && index < cmlcModels.count else {
            return nil
        }
        
        return cmlcModels[index]
    }
    
    func visionModelAtIndex(_ index: Int) -> VNCoreMLModel? {
        guard index < count && index < cmlcModels.count else {
            return nil
        }
        
        return cmlcModels[index].visionModel
    }
    
    mutating func loadModels() -> String? {
        var error: String?
        
        if let compiledModelURLs = Helper.getFiles(withExtension: ".mlmodelc", inPath: Helper.supportPath) {
            for compiledModelURL in compiledModelURLs {
                if let model = Model(fromCompiledModel: compiledModelURL) {
                    Log.i("Successfully loaded previously compiled model \(model.name)")
                    cmlcModels.append(model)
                } else {
                    let modelName = compiledModelURL.fileNameWithoutExtension()
                    Log.e("Failed to load previously compiled model \(modelName)")
                    error! += "Failed to load previously compiled model \(modelName)\n"
                }
            }
        } else {
            Log.i("No models were found, will prepare SqueezeNet")
            
            if let model = Model(withResourceName: "SqueezeNet", andExtension: "cmlc") {
                if model.state == .loaded {
                    Log.i("Successfully loaded model \(model.name)")
                    cmlcModels.append(model)
                    
                    do {
                        try model.saveCompiledModelURL()
                    } catch let error as CMLCError {
                        // Just an error, will try again on next app launch
                        Log.e("Error while trying to store compiled model \(model.name): \(error.rawValue)")
                    } catch {
                        Log.e("Error: \(error.localizedDescription)")
                    }
                } else {
                    Log.e("Failed to init model \(model.name)")
                    error! += "Failed to init model \(model.name)\n"
                }
            }
        }
        
        return error
    }
}
