//
//  Helper.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 04.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation

class Helper {
    
    static private(set) var supportPathURL: URL = {
        let fileManager = FileManager.default
        let URL = try! fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        return URL
    }()
    
    static private(set) var supportPath: String = {
        Log.d("supportPath = " + supportPathURL.path)
        return supportPathURL.path
    }()
    
    static func getFiles(withExtension ext: String, inPath path: String) -> [URL]? {
        guard ext.count > 1 && path.count > 1 else {
            Log.e("Invalid parameters extension .\(ext) path \(path)")
            return nil
        }
        
        var files: [URL] = []
        let fileNames = try! FileManager.default.contentsOfDirectory(atPath: path)
        for fileName in fileNames {
            if fileName.contains(ext) {
                let fileURL = URL(fileURLWithPath: path + "/" + fileName)
                files.append(fileURL)
                Log.d("Found compiled model \(files[files.count - 1].lastPathComponent)")
            }
        }
        
        return files.count > 0 ? files : nil
    }
    
    static func saveURL(_ url: URL, inPathURL pathURL: URL) throws -> URL? {
        let destURL = pathURL.appendingPathComponent(url.lastPathComponent)
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                Log.d("Will replace compiled model \(url.lastPathComponent)")
                _ = try fileManager.replaceItemAt(destURL, withItemAt: url)
            } else {
                try fileManager.moveItem(at: url, to: destURL)
            }
        } catch {
            Log.e("Error while saving URL \(url.absoluteString): \(error.localizedDescription)")
            throw CMLCError.fileSave
        }
        
        return destURL
    }
    
    static func deleteURL(_ url: URL) throws {
        let path = url.path
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            Log.e("File \(url.path) doesn't exist")
            throw CMLCError.fileExist
        }
        
        do {
            try fileManager.removeItem(atPath: path)
        } catch let error as NSError {
            Log.e("Error while deleting \(path)): \(error.localizedDescription)")
            throw CMLCError.fileDelete
        }
    }
    
    static func downloadFileURL(_ fileURL: URL, completionHandler: @escaping (URL?, CMLCError?) -> Void) {
        let destination = supportPathURL.appendingPathComponent(fileURL.lastPathComponent)
        Log.i("Will download \(fileURL.absoluteString)")
        
        DispatchQueue.global().async {
            var url: URL?
            var cmlcError: CMLCError?
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let request = URLRequest(url: fileURL)
            
            let downloadTask = session.downloadTask(with: request) { (location, response, error) in
                if let location = location, error == nil {
                    if let status = (response as? HTTPURLResponse)?.statusCode {
                        Log.d("Server status code \(status)")
                    }
                    
                    Log.d("Downloaded temporary file \(location.absoluteString)")
                    do {
                        let manager = FileManager.default
                        if manager.fileExists(atPath: destination.path) {
                            Log.d("File already exists, trying to remove it")
                            try manager.removeItem(at: destination)
                        }
                        
                        try manager.moveItem(at: location, to: destination)
                        url = destination
                        Log.i("File successfully downloaded at \(url!.absoluteString)")
                    } catch {
                        Log.e("Error while moving downloaded file from tmp: \(error.localizedDescription)")
                        cmlcError = CMLCError.fileSave
                    }
                } else {
                    Log.e("Error while downloading: \(error?.localizedDescription ?? "nil")")
                    cmlcError = CMLCError.downloadFail
                }
                
                DispatchQueue.main.async {
                    completionHandler(url, cmlcError)
                }
            }
            downloadTask.resume()
        }
    }
}

extension Float {
    
    func stringWithTwoDecimals() -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

extension URL {
    
    func fileNameWithoutExtension() -> String {
        return self.isFileURL ? self.deletingPathExtension().lastPathComponent : ""
    }
}
