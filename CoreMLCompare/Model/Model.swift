//
//  Model.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import Vision
import UIKit

struct Model {
    
    static let fileExtension = "mlmodel"
    static let compiledExtension = "mlmodelc"
    static let resourceExtenstion = "cmlc"
    static let confidenceMinLevel = Float(0.5)
    
    enum State: Int {
        case none
        case processing
        case loaded
        case enabled
    }
    
    static let colors = [UIColor.black, UIColor.darkGray, UIColor.lightGray, UIColor.gray, UIColor.red, UIColor.green, UIColor.blue, UIColor.cyan, UIColor.magenta, UIColor.orange, UIColor.purple, UIColor.brown]
    
    private(set) var visionModel: VNCoreMLModel?
    private(set) var name: String
    private(set) var state: State
    
    private(set) var object: String
    private(set) var confidence: String
    
    private(set) var minConfidence: Float
    private(set) var color: Int
    
    private(set) var compiledURL: URL?
    
    
    private enum CodingKeys: String, CodingKey {
        case name
        case state
        case compiledURL
        case minConfidence
        case color
    }
    
    
    // MARK: - Initializers
    init() {
        state = .none
        name = ""
        
        object = ""
        confidence = "0%"
        
        minConfidence = Model.confidenceMinLevel
        color = 0
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
    
    // MARK: - Model operations
    static func compileModelURL(_ url: URL, name: String) -> Model? {
        if let compiledModelURL = try? MLModel.compileModel(at: url) {
            if let compiledModel = try? MLModel(contentsOf: compiledModelURL) {
                var model = Model(withCoreMLModel: compiledModel, andName: name)
                model.compiledURL = compiledModelURL
                model.state = .enabled
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
                state = .none
            } else if state != .enabled {
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
        if result.confidence >= minConfidence {
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
    
    func isEditable() -> Bool {
        return state.rawValue >= State.loaded.rawValue
    }
}

// MARK: - Setters
extension Model {
    
    mutating func setStateProcessing() {
        state = .processing
    }
    
    mutating func enable() {
        if state == .loaded {
            state = .enabled
            Log.i("Enabled model \(name)")
        }
    }
    
    mutating func disable() {
        if state == .enabled {
            state = .loaded
            Log.i("Disabled model \(name)")
            
            object = ""
            confidence = "0%"
        }
    }
    
    mutating func changeNameTo(_ newName: String) {
        name = newName
    }
    
    mutating func setMinConfidence(_ newMinConfidence: Float) {
        minConfidence = newMinConfidence
    }
    
    mutating func changeColorTo(_ newColor: Int) {
        color = newColor
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
        
        minConfidence = try container.decode(Float.self, forKey: .minConfidence)
        color = try container.decode(Int.self, forKey: .color)
        
        object = ""
        confidence = "0%"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(state.rawValue, forKey: .state)
        try container.encode(compiledURL!.lastPathComponent, forKey: .compiledURL)
        try container.encode(minConfidence, forKey: .minConfidence)
        try container.encode(color, forKey: .color)
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
