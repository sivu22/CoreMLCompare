//
//  ResultsTableView.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 05.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

extension CMLCViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = resultsTableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        
        resultsTableView.updateCell(cell, withModel: models.modelAtIndex(indexPath.row))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        let firstModel = indexPath.row == 0
        
        // MARK: Delete
        if !firstModel, let model = models.modelAtIndex(indexPath.row), model.state == .loaded {
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
                let alert = UIAlertController(title: "", message: "Are you sure you want to delete the model \(model.name)?", preferredStyle: UIAlertControllerStyle.alert)
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction!) in
                    do {
                        try self.models.deleteModelAtIndex(indexPath.row)
                        self.resultsTableView.reloadRows(at: [indexPath], with: .none)
                    } catch let error as CMLCError {
                        let alert = error.createAlert()
                        self.present(alert, animated: true, completion: nil)
                    } catch {
                    }
                })
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction!) in
                })
                alert.addAction(yesAction)
                alert.addAction(noAction)
                
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            actions.append(delete)
        }
        
        // MARK: Edit
        if let model = models.modelAtIndex(indexPath.row), model.state == .loaded {
            let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            }
            
            edit.backgroundColor = UIColor.lightGray
            actions.append(edit)
        }
        
        // MARK: Add
        if !firstModel, let currModel = models.modelAtIndex(indexPath.row), currModel.state != .processing {
            let add = UITableViewRowAction(style: .normal, title: "Add") { action, index in
                if let pasteboardText = UIPasteboard.general.string, let url = Model.getURLFromText(pasteboardText) {
                    // Remove old model
                    do {
                        try self.models.deleteModelAtIndex(index.row)
                        self.resultsTableView.reloadRows(at: [index], with: .none)
                    } catch let error as CMLCError {
                        let alert = error.createAlert()
                        self.present(alert, animated: true, completion: nil)
                        return
                    } catch {
                        Log.e("Failed to remove model at index \(index.row): \(error.localizedDescription)")
                    }
                    
                    // Update UI and start downloading
                    self.models.setStateProcessingAtIndex(index.row)
                    self.resultsTableView.updateCellAtIndex(index, withTitle: nil, andDetail: "Downloading...")
                    
                    let urlDownload = URLDownload(url: url, saveLocationURL: Helper.supportPathURL.appendingPathComponent(url.lastPathComponent), atIndex: indexPath)
                    urlDownload.delegate = self
                    urlDownload.start() { (downloadURL, error) in
                        if let error = error {
                            self.models.setModelAtIndex(index.row, withModel: Model())
                            self.resultsTableView.reloadRows(at: [index], with: .none)
                            
                            let alert = error.createAlert()
                            self.present(alert, animated: true, completion: nil)
                        } else if let downloadURL = downloadURL {
                            // We have the model URL, time to process it
                            self.prepareModelURL(downloadURL, atIndex: index)
                        }
                    }
                } else {
                    let infoPopup = CMLCError.createAlert(withText: "No appropriate CoreML model was found in the clipboard.\nCopy model URL to clipboard first or click the model file after download to import it inside the app.", andTitle: "Adding a model")
                    self.present(infoPopup, animated: true, completion: nil)
                }
            }
            
            add.backgroundColor = UIColor.blue
            actions.append(add)
        }
        
        return actions
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        if tableView is EditingRow {
            let cmlcTableView = tableView as! EditingRow
            cmlcTableView.beginEditingRowAt(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if tableView is EditingRow, let indexPath = indexPath {
            let cmlcTableView = tableView as! EditingRow
            cmlcTableView.endEditingRowAt(indexPath)
        }
    }
}

// MARK: - URLDownloadDelegate
extension CMLCViewController: URLDownloadDelegate {
    
    func reportProgress(_ percentage: Int, atIndex index: IndexPath) {
        resultsTableView.updateCellAtIndex(index, withTitle: nil, andDetail: "Downloading... \(percentage)%")
    }
}

// MARK: - Model processing
extension CMLCViewController {
    
    func prepareModelURL(_ modelURL: URL, atIndex index: IndexPath) {
        let modelName = modelURL.fileNameWithoutExtension()
        resultsTableView.updateCellAtIndex(index, withTitle: nil, andDetail: "Compiling model \(modelName)...")
        
        // Compile new model
        DispatchQueue.global().async {
            let model = Model.compileModelURL(modelURL, name: modelName)
            DispatchQueue.main.async {
                if var model = model {
                    self.resultsTableView.updateCellAtIndex(index, withTitle: "\(model.name):", andDetail: "Saving and cleaning up...")
                    
                    // Store model and clean up
                    DispatchQueue.global().async {
                        var success = false
                        do {
                            try model.saveCompiledModelURL()
                            self.models.setModelAtIndex(index.row, withModel: model)
                            try Helper.deleteURL(modelURL)
                            success = true
                        } catch let error as CMLCError {
                            Log.e("Error while trying to store compiled model \(model.name): \(error.rawValue)")
                        } catch {
                            Log.e("Error: \(error.localizedDescription)")
                        }
                        
                        // Update UI with new model
                        DispatchQueue.main.async {
                            if success {
                                self.resultsTableView.updateCellAtIndex(index, withModel: model)
                            } else {
                                self.resultsTableView.updateCellAtIndex(index, withModel: nil)
                                
                                let alert = CMLCError.addModelFail.createAlert()
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - NewModelDelegate
extension CMLCViewController: NewModelDelegate {
    
    func onImport(newModelURL url: URL, atIndex index: Int) {
        Log.i("Will import model \(url.fileNameWithoutExtension()) at index \(index)")
        prepareModelURL(url, atIndex: IndexPath(row: index, section: 0))
    }
    
    func onCancel(newModelURL url: URL) {
        Log.i("User canceled importing of new model \(url.fileNameWithoutExtension())")
        do {
            try Helper.deleteURL(url)
        } catch let error as CMLCError {
            Log.e("Error while trying to delete downlaoded model URL \(url.absoluteString): \(error.rawValue)")
        } catch {
            Log.e("Error while trying to delete downloaded model URL \(url.absoluteString): \(error.localizedDescription)")
        }
    }
}
