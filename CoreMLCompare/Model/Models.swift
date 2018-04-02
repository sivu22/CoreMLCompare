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
        
        for _ in 1..<count {
            cmlcModels.append(Model())
        }
        
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
        var index = 1
        
        if let compiledModelURLs = Helper.getFiles(withExtension: Model.compiledExtension, inPath: Helper.supportPath) {
            for compiledModelURL in compiledModelURLs {
                if let model = Model(fromCompiledModel: compiledModelURL) {
                    Log.i("Successfully loaded previously compiled model \(model.name)")
                    setModelAtIndex(index, withModel: model)
                    index += 1
                } else {
                    let modelName = compiledModelURL.fileNameWithoutExtension()
                    Log.e("Failed to load previously compiled model \(modelName)")
                    error! += "Failed to load previously compiled model \(modelName)\n"
                }
            }
        } else {
            Log.i("No models were found, will prepare SqueezeNet")
            
            if var model = Model(withResourceName: "SqueezeNet", andExtension: Model.resourceExtenstion) {
                if model.state == .loaded {
                    Log.i("Successfully loaded model \(model.name)")
                    
                    do {
                        try model.saveCompiledModelURL()
                        setModelAtIndex(index, withModel: model)
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
    
    mutating func deleteModelAtIndex(_ index: Int) throws {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        let model = cmlcModels[index]
        guard model.state == .loaded else {
            Log.i("No model found (or not ready) at index \(index)")
            return
        }
        
        defer {
            cmlcModels[index] = Model()
        }
        
        try cmlcModels[index].destroy()
    }
    
    mutating func setModelAtIndex(_ index: Int, withModel model: Model) {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        cmlcModels[index] = model
        Log.i("Model \(model.name) set up at index \(index)")
    }
    
    mutating func setStateProcessingAtIndex(_ index: Int) {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        cmlcModels[index].setStateProcessing()
    }
}
