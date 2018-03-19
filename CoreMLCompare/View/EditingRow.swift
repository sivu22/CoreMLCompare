//
//  EditingRow.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 18.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

protocol EditingRow: AnyObject {
    
    var editingRow: IndexPath? { get }
    
    func beginEditingRowAt(_ indexPath: IndexPath)
    func endEditingRowAt(_ indexPath: IndexPath)
    func isEditingRowAt(_ indexPath: IndexPath) -> Bool
}

extension EditingRow where Self:CMLCTableView {
    
    func beginEditingRowAt(_ indexPath: IndexPath) {
        editingRow = indexPath
    }
    
    func endEditingRowAt(_ indexPath: IndexPath) {
        if editingRow == indexPath {
            editingRow = nil
        }
    }
    
    func isEditingRowAt(_ indexPath: IndexPath) -> Bool {
        if editingRow == indexPath {
            return true
        }
        
        return false
    }
}
