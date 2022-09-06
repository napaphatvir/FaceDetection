//
//  ImageViewController.swift
//  FaceDetection
//
//  Created by Napaphat on 2/9/2565 BE.
//

import UIKit
import MLKitFaceDetection

class ImageViewController: UIViewController {
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = image
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cropImageButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Crop",
                               style: .plain,
                               target: self,
                               action: #selector(tapCrop))
    }()
    
    var image: UIImage?
    private var cropImage: [UIImage] = []
    private var faces: [Face] = []
    private let faceDetector = FaceDetectorManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        processingFaceDetection()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cropImage",
           let vc = segue.destination as? CropImageViewController {
            vc.cropImage = cropImage
        }
    }
    
    private func configureView() {
        view.addSubview(imageView)
        
        navigationItem.rightBarButtonItem = cropImageButton
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    private func processingFaceDetection() {
        guard let image = image else { return }
        faceDetector.process(with: image) { [weak self] faces in
            guard let self = self else { return }
            self.faces = faces
            self.faces.enumerated().forEach { (index, face) in
                let view = UIView()
                view.layer.borderColor = UIColor.red.cgColor
                view.layer.borderWidth = 2
                view.backgroundColor = .clear
                view.frame = face.convertRect(source: image,
                                              imageView: self.imageView)
                self.imageView.addSubview(view)
            }
        }
    }
    
    @objc func tapCrop() {
        if faces.isEmpty {
            let alertController = UIAlertController(title: "Error",
                                                    message: "No face found in this image.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .default))
            self.present(alertController, animated: true)
            return
        }
        guard let image = image else { return }
        cropImage = faceDetector.croppingFace(
            faces: faces,
            in: image,
            padding: UIEdgeInsets(top: 50,
                                  left: 50,
                                  bottom: 50,
                                  right: 50)
        )
        performSegue(withIdentifier: "cropImage", sender: self)
    }
}
