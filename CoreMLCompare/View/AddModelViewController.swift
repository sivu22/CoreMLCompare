//
//  AddModelViewController.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 23.04.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import UIKit

protocol NewModelDelegate {
    
    func onCancel(newModelURL: URL)
    func onImport(newModelURL: URL, atIndex: Int)
}

class AddModelViewController: UIViewController {

    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var indexPickerView: UIPickerView!
    
    var newModelURL: URL!
    var models: Models!
    
    var delegate: NewModelDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Log.d("Adding a new model from URL \(newModelURL)")
        
        selectView.layer.cornerRadius = 10
        selectView.layer.masksToBounds = true
        
        indexPickerView.dataSource = self
        indexPickerView.delegate = self
        indexPickerView.selectRow(1, inComponent: 0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func cancelImport(_ sender: UIButton) {
        dismiss(animated: true, completion: {
            self.delegate?.onCancel(newModelURL: self.newModelURL)
        })
    }
    
    @IBAction func importModel(_ sender: UIButton) {
        dismiss(animated: true, completion: {
            self.delegate?.onImport(newModelURL: self.newModelURL, atIndex: self.indexPickerView.selectedRow(inComponent: 0))
        })
    }
}

// MARK: - UIPickerViewDataSource
extension AddModelViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return models.count
    }
}

// MARK: - UIPickerViewDelegate
extension AddModelViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let name = models.modelAtIndex(row)?.name ?? ""
        return "\(row + 1) - \(name.isEmpty ? "<Empty>" : name)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            pickerView.selectRow(1, inComponent: 0, animated: true)
        }
    }
}
