//
//  EditModelTableViewController.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 29.04.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import UIKit

protocol EditModelDelegate {
    
    func onEdit(model: Model, atIndex: Int)
}

class EditTableViewController: UITableViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet weak var colorPickerView: UIPickerView!
    
    var model: Model?
    var index: Int?
    var delegate: EditModelDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if model == nil {
             model = Model()
        }
        if index == nil {
            index = 1
        }
        
        nameTextField.delegate = self
        colorPickerView.dataSource = self
        colorPickerView.delegate = self
        
        nameTextField.text = model!.name
        let confidence = Int(model!.minConfidence * 100)
        confidenceLabel.text = "\(confidence)%"
        confidenceSlider.value = Float(confidence)
        colorPickerView.selectRow(model!.color, inComponent: 0, animated: false)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss()
    }
    
    @IBAction func onDone(_ sender: Any) {
        if nameTextField.text!.count > 0 {
            model!.changeNameTo(nameTextField.text!)
        }
        model!.setMinConfidence(confidenceSlider.value / 100)
        model!.changeColorTo(colorPickerView.selectedRow(inComponent: 0))
        
        delegate?.onEdit(model: model!, atIndex: index!)
        dismiss()
    }
    
    @IBAction func confidenceChanged(_ sender: Any) {
        confidenceLabel.text = "\(Int(confidenceSlider.value))%"
    }
    
    func dismiss() {
        if nameTextField.isFirstResponder {
            nameTextField.resignFirstResponder()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension EditTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        
        return true
    }
}

// MARK: - UIPickerViewDataSource
extension EditTableViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Model.colors.count
    }
}

// MARK: - UIPickerViewDelegate
extension EditTableViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: Model.colors[row].name(), attributes: [.foregroundColor: Model.colors[row]])
    }
}

