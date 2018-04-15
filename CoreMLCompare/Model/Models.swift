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
        var error = ""
        var loadedModels = false
        
        for i in 1..<count {
            let key = "model\(i)"
            do {
                if var modelDecoded = try Model.userDefaultsLoadKey(key) {
                    if let loadError = modelDecoded.loadCompiledModel() {
                        Helper.removeSetting(forKey: key)
                        
                        Log.e("Index \(i): \(loadError)")
                        error += loadError + "\n"
                    } else {
                        setModelAtIndex(i, withModel: modelDecoded, andSave: false)
                        loadedModels = true
                    }
                }
            } catch let decodeError {
                Log.e("Loading previously compiled model failed: \(decodeError.localizedDescription)")
                error += "Failed to restore model at index \(i)\n"
            }
        }
        
        if !loadedModels {
            Log.i("No models were found, will prepare SqueezeNet")
            
            if var model = Model(withResourceName: "SqueezeNet", andExtension: Model.resourceExtenstion) {
                if model.state == .loaded {
                    Log.i("Successfully loaded model \(model.name)")
                    
                    do {
                        try model.saveCompiledModelURL()
                        setModelAtIndex(1, withModel: model)
                    } catch let error as CMLCError {
                        // Just an error, will try again on next app launch
                        Log.e("Error while trying to store compiled model \(model.name): \(error.rawValue)")
                    } catch {
                        Log.e("Error: \(error.localizedDescription)")
                    }
                } else {
                    Log.e("Failed to init model \(model.name)")
                    error += "Failed to init model \(model.name)\n"
                }
            }
        }
        
        if error.count > 0 {
            return error
        }
        return nil
    }
    
    mutating func deleteModelAtIndex(_ index: Int) throws {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        guard cmlcModels[index].state == .loaded else {
            Log.i("No model found (or not ready) at index \(index)")
            return
        }
        
        defer {
            cmlcModels[index] = Model()
            let key = "model\(index)"
            Helper.removeSetting(forKey: key)
        }
        
        try cmlcModels[index].destroy()
    }
    
    mutating func setModelAtIndex(_ index: Int, withModel model: Model, andSave save: Bool = true) {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        cmlcModels[index] = model
        Log.i("Model \(model.name) set up at index \(index)")
        
        if save {
            do {
                let key = "model\(index)"
                if model.state == .none {
                    Helper.removeSetting(forKey: key)
                } else {
                    try cmlcModels[index].userDefaultsSaveKey(key)
                }
            } catch {
                Log.e("Model at index \(index) will not be available after app restart!")
            }
        }
    }
    
    mutating func setStateProcessingAtIndex(_ index: Int) {
        guard index > 0 && index < cmlcModels.count else {
            Log.e("Bad index: \(index)")
            return
        }
        
        cmlcModels[index].setStateProcessing()
    }
}
