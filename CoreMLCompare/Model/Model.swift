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
    
    private(set) var compiledURL: URL?
    
    init() {
        state = .none
        name = ""
        
        object = ""
        confidence = "0%"
    }
    
    init(withCoreMLModel model: MLModel, andName givenName: String = "NoName") {
        self.init()
        name = givenName
        
        visionModel = try? VNCoreMLModel(for: model)
        if visionModel == nil {
            Log.e("Failed to init \(name) model")
        } else {
            state = .loaded
        }
    }
    
    init?(withResourceName name: String, andExtension ext: String) {
        guard let model2URL = Bundle.main.url(forResource: name, withExtension: ext) else {
            Log.e("Failed to create URL from resource \(name).\(ext)")
            return nil
        }
        
        let (model, compiledURL) = Model.compileModelURL(model2URL, name: name)
        if let model = model {
            self = model
            self.compiledURL = compiledURL
        } else {
            return nil
        }
    }
    
    init?(fromCompiledModel compiledModelURL: URL) {
        self.init()
        
        if let compiledModel = try? MLModel(contentsOf: compiledModelURL) {
            self = Model(withCoreMLModel: compiledModel, andName: compiledModelURL.fileNameWithoutExtension())
            self.compiledURL = compiledModelURL
        } else {
            Log.e("Failed to read \(compiledModelURL.lastPathComponent) model")
            return nil
        }
    }
    
    private static func compileModelURL(_ url: URL, name: String) -> (Model?, URL?) {
        if let compiledModelURL = try? MLModel.compileModel(at: url) {
            if let compiledModel = try? MLModel(contentsOf: compiledModelURL) {
                let model = Model(withCoreMLModel: compiledModel, andName: name)
                return (model, compiledModelURL)
            } else {
                Log.e("Failed to read \(url.lastPathComponent) model")
            }
        } else {
            Log.e("Failed to compile model \(url.lastPathComponent)")
        }
        
        return (nil, nil)
    }
    
    func saveCompiledModelURL() throws {
        guard let url = compiledURL else {
            throw CMLCError.modelBadURL
        }
        
        do {
            try Helper.saveURL(url, inPathURL: Helper.supportPathURL)
        } catch {
            throw error
        }
    }
    
    func destroy() throws {
        guard let url = compiledURL else {
            throw CMLCError.modelBadURL
        }
        
        do {
            try Helper.deleteURL(url)
            Log.d("Deleted model \(name)")
        } catch {
            throw error
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
