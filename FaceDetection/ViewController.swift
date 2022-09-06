//
//  ViewController.swift
//  FaceDetection
//
//  Created by Napaphat on 2/9/2565 BE.
//

import UIKit
import AVFoundation
import MLKitFaceDetection
import MLKitVision

class ViewController: UIViewController {
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let output = AVCapturePhotoOutput()
    private var image: UIImage?
    private let session = AVCaptureSession()
    
    
    private lazy var captureButton: UIButton = {
        let button = UIButton()
        button.setTitle("Capture", for: .normal)
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage",
           let vc = segue.destination as? ImageViewController {
            vc.image = image
        }
    }
    
    private func configureView() {
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                  constant: -16),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 120),
            captureButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureCamera() {
        do {
            guard let device = AVCaptureDevice.default(for: .video)
            else { return }
            let input = try AVCaptureDeviceInput(device: device)
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = false
            let outputQueue = DispatchQueue(label: "backgroud.face.detection")
            videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(previewLayer, at: 0)
            
            session.startRunning()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @objc private func capturePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(),
                            delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
//        image = UIImage(data: data)
        
//        guard let cgImage = photo.cgImageRepresentation() else { return }
//        let orientationInt = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32
//        let cgOrinetation = CGImagePropertyOrientation(rawValue: orientationInt ?? 0) ?? .up
//        let imageOrientation = UIImage.Orientation(cgOrinetation)
        
        image = UIImage(data: data)
        
        performSegue(withIdentifier: "showImage",
                     sender: self)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { print("error"); return }
        
        let vision = VisionImage(buffer: sampleBuffer)
        vision.orientation = .right
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        
        let options = FaceDetectorOptions()
        options.performanceMode = .fast
        let faceDetector = FaceDetector.faceDetector(options: options)
        var faces: [Face] = []
        
        do {
            faces = try faceDetector.results(in: vision)
        } catch {
            print("Failed to detect faces with error: \(error.localizedDescription).")
        }
        DispatchQueue.main.sync { [weak self] in
            guard let self = self else { return }
            
            self.previewLayer.sublayers?.forEach {
                if $0.name?.contains("detect_layer") == true {
                    $0.removeFromSuperlayer()
                }
            }
            
            guard !faces.isEmpty else {
                print("On-Device face detector returned no results.")
                return
            }
            
            faces.enumerated().forEach { (index, face) in
                let normalizedRect = CGRect(
                    x: face.frame.origin.x / imageWidth,
                    y: face.frame.origin.y / imageHeight,
                    width: face.frame.size.width / imageWidth,
                    height: face.frame.size.height / imageHeight
                )
                
                let standardizedRect = self.previewLayer.layerRectConverted(
                  fromMetadataOutputRect: normalizedRect
                ).standardized
                
                let layer = CALayer()
                layer.name = "detect_layer_\(index)"
                layer.borderColor = UIColor.red.cgColor
                layer.borderWidth = 2
                layer.backgroundColor = UIColor.clear.cgColor
                layer.frame = standardizedRect
                
                self.previewLayer.addSublayer(layer)
            }
        }
    }
}
