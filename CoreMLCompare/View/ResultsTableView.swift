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
        
        if let model = models.modelAtIndex(indexPath.row), model.state == .loaded {
            let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            }
            
            edit.backgroundColor = UIColor.lightGray
            actions.append(edit)
        }
        
        if !firstModel {
            let add = UITableViewRowAction(style: .normal, title: "Add") { action, index in
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
