//
//  CMLCViewController.swift
//  CoreMLCompare
//
//  Created by Cristian Sava on 01.03.18.
//  Copyright © 2018 Cristian Sava. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CMLCViewController: UIViewController {

    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var resultsTableView: UITableView!
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    var models: Models!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        models = Models()
        
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setUpModels()
        
        do {
            try setUpSession()
        } catch let error as CMLCError {
            let alert = error.createAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = CMLCError.createAlert(withText: error.localizedDescription)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) -> Void in
            let uiOrientation = UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
            
            var orientation: AVCaptureVideoOrientation
            switch (uiOrientation) {
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .landscapeRight:
                orientation = .landscapeRight
            default:
                orientation = .portrait
            }
            
            self.previewLayer?.connection?.videoOrientation = orientation
            self.previewLayer?.frame = self.videoImageView.frame
        }, completion: { (context) -> Void in
        })
    }
}

// MARK: - Setup

extension CMLCViewController {
    
    func setUpModels() {
        var error: String?
        
        DispatchQueue.global().async {
            error = self.models.loadModels()
            
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
                self.resultsTableView.reloadData()
                
                if let error = error {
                    let alert = CMLCError.createAlert(withText: error)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func setUpSession() throws {
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CMLCError.avCaptureDevice
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            throw CMLCError.avDeviceInput
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        videoImageView.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }
}

// MARK: - Video capture

extension CMLCViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Log.e("Failed to get pixelbuffer")
            return
        }
        
        var requests = [VNCoreMLRequest]()
        for (index, var cmlcModel) in models.cmlcModels.enumerated() {
            if cmlcModel.state == .loaded {
                let request = VNCoreMLRequest(model: cmlcModel.visionModel!) { request, error in
                    guard let results = request.results as? [VNClassificationObservation] else {
                        Log.e("Could not obtain results for model \(cmlcModel.name)")
                        return
                    }
                    guard let firstResult = results.first else {
                        Log.e("Failed to get first result for model \(cmlcModel.name)")
                        return
                    }
                    
                    if cmlcModel.objectClassified(firstResult) {
                        self.models.cmlcModels[index] = cmlcModel
                        DispatchQueue.main.async {
                            self.resultsTableView.reloadRows(at: [index])
                        }
                    }
                }
                // Matches all current Apple models
                request.imageCropAndScaleOption = .centerCrop
                
                requests.append(request)
            }
        }
        
        // Waiting for Apple to fix the perform request array bug
        for request in requests {
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
}
