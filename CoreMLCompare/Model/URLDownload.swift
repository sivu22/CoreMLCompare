//
//  Download.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 07.04.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation

class URLDownload: NSObject {
    
    private(set) var downloadURL: URL
    private(set) var destinationURL: URL
    private(set) var downloadIndex: IndexPath
    private var completionHandler: ((URL?, CMLCError?) -> Void)?
    
    weak var delegate: URLDownloadDelegate?
    
    private var percentage: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.reportProgress(self.percentage, atIndex: self.downloadIndex)
            }
        }
    }
    
    init(url: URL, saveLocationURL: URL, atIndex: IndexPath) {
        downloadURL = url
        destinationURL = saveLocationURL
        downloadIndex = atIndex
        completionHandler = nil
    }
    
    func start(_ completionHandler: ((URL?, CMLCError?) -> Void)? = nil) {
        self.completionHandler = completionHandler
        downloadFileURL()
    }
    
    private func downloadFileURL() {
        Log.i("Will download \(downloadURL.absoluteString)")
        
        DispatchQueue.global().async {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            let request = URLRequest(url: self.downloadURL)
            
            let downloadTask = session.downloadTask(with: request)
            downloadTask.resume()
        }
    }
}

// MARK: - URLSession delegates
extension URLDownload: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var cmlcError: CMLCError?
        
        if let error = error {
            Log.e("Error while downloading: \(error.localizedDescription)")
            cmlcError = CMLCError.downloadFail
        }
        
        DispatchQueue.main.async {
            self.completionHandler?(nil, cmlcError)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        var url: URL?
        var cmlcError: CMLCError?
        
        Log.d("Downloaded temporary file \(location.absoluteString)")
        do {
            let manager = FileManager.default
            if manager.fileExists(atPath: self.destinationURL.path) {
                Log.d("File already exists, trying to remove it")
                try manager.removeItem(at: self.destinationURL)
            }
            
            try manager.moveItem(at: location, to: self.destinationURL)
            url = self.destinationURL
            Log.i("File successfully downloaded at \(url!.absoluteString)")
        } catch {
            Log.e("Error while moving downloaded file from tmp: \(error.localizedDescription)")
            cmlcError = CMLCError.fileSave
        }
        
        DispatchQueue.main.async {
            self.completionHandler?(url, cmlcError)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        percentage = Int(100 * Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
    }
}
