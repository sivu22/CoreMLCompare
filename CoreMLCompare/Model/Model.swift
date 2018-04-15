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
    
    static let fileExtension = "mlmodel"
    static let compiledExtension = "mlmodelc"
    static let resourceExtenstion = "cmlc"
    
    enum State: Int {
        case none
        case processing
        case loaded
        case enabled
    }
    
    private(set) var visionModel: VNCoreMLModel?
    private(set) var name: String
    private(set) var state: State
    
    private(set) var object: String
    private(set) var confidence: String
    
    private(set) var compiledURL: URL?
    
    
    private enum CodingKeys: String, CodingKey {
        case name
        case state
        case compiledURL
    }
    
    
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
        
        let model = Model.compileModelURL(model2URL, name: name)
        if let model = model {
            self = model
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
    
    mutating func setStateProcessing() {
        state = .processing
    }
    
    static func compileModelURL(_ url: URL, name: String) -> Model? {
        if let compiledModelURL = try? MLModel.compileModel(at: url) {
            if let compiledModel = try? MLModel(contentsOf: compiledModelURL) {
                var model = Model(withCoreMLModel: compiledModel, andName: name)
                model.compiledURL = compiledModelURL
                return model
            } else {
                Log.e("Failed to read \(url.lastPathComponent) model")
            }
        } else {
            Log.e("Failed to compile model \(url.lastPathComponent)")
        }
        
        return nil
    }
    
    mutating func saveCompiledModelURL() throws {
        guard let url = compiledURL else {
            throw CMLCError.modelBadURL
        }
        
        do {
            compiledURL = try Helper.saveURL(url, inPathURL: Helper.supportPathURL)
        } catch {
            throw error
        }
    }
    
    mutating func loadCompiledModel() -> String? {
        var error: String?
        
        defer {
            if let error = error {
                Log.e(error)
            } else {
                Log.d("Successfully loaded compiled model \(name)")
            }
        }
        
        guard let url = compiledURL else {
            error = "Compiled model URL is missing for model \(name)"
            return error
        }
        
        if let compiledModel = try? MLModel(contentsOf: url) {
            visionModel = try? VNCoreMLModel(for: compiledModel)
            if visionModel == nil {
                error = "Failed to init \(name) model"
            } else {
                state = .loaded
            }
        } else {
            error = "Failed to read \(url.lastPathComponent) model"
        }
        
        return error
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
    
    static func getURLFromText(_ text: String) -> URL? {
        guard text.hasSuffix(fileExtension) else {
            return nil
        }
        
        return URL(string: text)
    }
}

// MARK: - Codable
extension Model: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        if let stated = State(rawValue: try container.decode(Int.self, forKey: .state)) {
            state = stated
        } else {
            throw CMLCError.invalidData
        }
        let modelFileName = try container.decode(String.self, forKey: .compiledURL)
        compiledURL = Helper.supportPathURL.appendingPathComponent(modelFileName)
        
        object = ""
        confidence = "0%"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(state.rawValue, forKey: .state)
        try container.encode(compiledURL!.lastPathComponent, forKey: .compiledURL)
    }
}

// MARK: - UserDefaults
extension Model {
    
    func userDefaultsSaveKey(_ key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        Helper.saveSetting(data, forKey: key)
    }
    
    static func userDefaultsLoadKey(_ key: String) throws -> Model? {
        if let data = Helper.loadSetting(forKey: key) {
            let decoder = JSONDecoder()
            let modelDecoded = try decoder.decode(Model.self, from: data)
            return modelDecoded
        }
        
        return nil
    }
    
    static func userDefaultsDeleteKey(_ key: String) {
        Helper.removeSetting(forKey: key)
    }
}
