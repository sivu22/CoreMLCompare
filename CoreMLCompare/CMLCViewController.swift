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
    @IBOutlet weak var objectLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var model: VNCoreMLModel?
    private var modelError: String?
    private var modelOK = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modelError = setUpModels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try setupSession()
        } catch let error as CMLCError {
            let alert = error.createAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = CMLCError.createAlert(withText: error.localizedDescription)
            present(alert, animated: true, completion: nil)
        }
        
        if let error = modelError {
            modelOK = false
            
            let alert = CMLCError.createAlert(withText: error)
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

extension CMLCViewController {
    
    func setUpModels() -> String? {
        var error: String?
        
        model = try? VNCoreMLModel(for: MobileNet().model)
        if model == nil {
            error = "Failed to init MobileNet model!"
        }
        
        return error
    }
    
    func setupSession() throws {
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

extension CMLCViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        guard modelOK else {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixelbuffer")
            return
        }
        
        let request = VNCoreMLRequest(model: model!) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                print("Could not obtain results")
                return
            }
            guard let firstResult = results.first else {
                print("Failed to get first result")
                return
            }
            
            if firstResult.confidence > 0.5 {
                DispatchQueue.main.async {
                    self.objectLabel.text = firstResult.identifier.localizedCapitalized
                    self.confidenceLabel.text = String(firstResult.confidence * 100) + "%"
                }
            }
        }
        // Matches all current Apple models
        request.imageCropAndScaleOption = .centerCrop
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
