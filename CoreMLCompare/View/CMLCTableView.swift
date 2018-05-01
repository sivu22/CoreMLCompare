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
            cell.textLabel!.textColor = Model.colors[model.color]
            cell.detailTextLabel!.text = model.confidence
            cell.detailTextLabel!.textColor = Model.colors[model.color]
        } else {
            cell.textLabel!.text = "None"
            cell.textLabel!.textColor = UIColor.black
            cell.detailTextLabel!.text = "Swipe right to add a new CoreML model."
            cell.detailTextLabel!.textColor = UIColor.black
        }
    }
    
    func updateCellAtIndex(_ index: IndexPath, withModel model: Model?) {
        if !isEditingRowAt(index) {
            if let cell = self.cellForRow(at: index) {
                updateCell(cell, withModel: model)
            }
        }
    }
    
    func updateCellAtIndex(_ index: IndexPath, withTitle title: String?, andDetail detail: String?) {
        if let cell = self.cellForRow(at: index) {
            if let title = title {
                cell.textLabel!.text = title
            }
            
            if let detail = detail {
                cell.detailTextLabel!.text = detail
            }
        }
    }

}
