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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
