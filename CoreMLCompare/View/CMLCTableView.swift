//
//  CMLCTableView.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 18.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import UIKit

class CMLCTableView: UITableView, EditingRow {
    
    var editingRow: IndexPath?
    
    func updateCell(_ cell: UITableViewCell, withModel model: Model?) {
        if let model = model, model.state == .loaded {
            cell.textLabel!.text = model.name + ": " + model.object
            cell.detailTextLabel!.text = model.confidence
        } else {
            cell.textLabel!.text = "None"
            cell.detailTextLabel!.text = "Swipe right to add a new CoreML model."
        }
    }
    
    func updateCellAtIndex(_ index: IndexPath, withModel model: Model?) {
        if !isEditingRowAt(index) {
            if let cell = self.cellForRow(at: index) {
                updateCell(cell, withModel: model)
            }
        }
    }

}
