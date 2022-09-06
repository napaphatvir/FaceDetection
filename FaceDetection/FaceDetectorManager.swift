//
//  FaceDetectorManager.swift
//  FaceDetection
//
//  Created by Napaphat on 6/9/2565 BE.
//

import Foundation
import MLKitFaceDetection
import MLKitVision

final class FaceDetectorManager {
    func process(with image: UIImage, completion: (([Face]) -> ())?) {
        let _image: UIImage = fixedImageOrientation(image)
        
        //FaceDetector options
        let options = FaceDetectorOptions()
        options.performanceMode = .fast
        
        //VisionImage
        let visionImage = VisionImage(image: _image)
        visionImage.orientation = _image.imageOrientation
        
        //FaceDetector
        let faceDetector = FaceDetector.faceDetector(options: options)
        faceDetector.process(visionImage) { faces, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                return
            }
            
            guard let _faces = faces, !_faces.isEmpty else {
                print("Error: No faces found")
                return
            }
            
            completion?(_faces)
        }
    }
    
    func croppingFace(faces: [Face], in image: UIImage, padding: UIEdgeInsets = .zero) -> [UIImage] {
        let _image = fixedImageOrientation(image)
        guard let cgImage = _image.cgImage
        else { return [] }
        
        return faces.compactMap { face in
            let screen = UIScreen.main.bounds
            let scale = min(image.size.width / screen.width,
                            image.size.height / screen.height)
            let top = padding.top * scale
            let bottom = padding.bottom * scale
            let left = padding.left * scale
            let right = padding.right * scale
            
            var frame = face.frame
            frame.size.width += left + right
            frame.size.height += top + bottom
            frame.origin.x -= (left + right) / 2
            frame.origin.y -= (top + bottom) / 2
            
            guard let result = cgImage.cropping(to: frame)
            else { return nil }
            return UIImage(cgImage: result,
                           scale: 1,
                           orientation: _image.imageOrientation)
        }
    }
}

//MARK: Private Method
private extension FaceDetectorManager {
    func fixedImageOrientation(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? image
    }
}

//MARK: Extension Face Interface
extension Face {
    func convertRect(source: UIImage, imageView: UIImageView) -> CGRect {
        let imageViewHeight: CGFloat = imageView.bounds.height
        let imageViewWidth: CGFloat = imageView.bounds.width
        let imageHeight: CGFloat = source.size.height
        let imageWidth: CGFloat = source.size.width
        
        let aspectWidth: CGFloat = imageViewWidth / imageWidth
        let aspectHeight: CGFloat = imageViewHeight / imageHeight
        let scale: CGFloat = min(aspectWidth, aspectHeight)
        let offsetX: CGFloat = (imageViewWidth - imageWidth * scale) / 2
        let offsetY: CGFloat = (imageViewHeight - imageHeight * scale) / 2
        return CGRect(x: (self.frame.origin.x * scale) + offsetX,
                      y: (self.frame.origin.y * scale) + offsetY,
                      width: self.frame.width * scale,
                      height: self.frame.height * scale)
    }
}
