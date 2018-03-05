//
//  ResultsTableView.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 05.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func reloadRows(at indexes: [Int], in section: Int = 0, withAnimation animation: UITableViewRowAnimation = .none) {
        var indexArray = [] as [IndexPath]
        for index in indexes {
            let indexPath = IndexPath(row: index, section: section)
            indexArray.append(indexPath)
        }
        
        self.reloadRows(at: indexArray, with: animation)
    }
}

extension CMLCViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = resultsTableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        
        if let model = models.modelAtIndex(indexPath.row) {
            cell.textLabel!.text = model.name + ": " + model.object
            cell.detailTextLabel!.text = model.confidence
        } else {
            cell.textLabel!.text = "None"
            cell.detailTextLabel!.text = "Swipe right to add a new CoreML model."
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
}
