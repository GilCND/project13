//
//  ViewController.swift
//  project13
//
//  Created by Felipe Gil on 2021-07-09.
//
import CoreImage
import UIKit
//TODO
#warning("Make the Change Filter button change its title to show the name of the currently filter")
#warning("Try more than 1 slider with different properties")

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var intensity: UISlider!
    
    var currentImage: UIImage?
    lazy var context: CIContext = CIContext()
    var currentFilter: CIFilter!
    
    let loadingActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = .white
        indicator.startAnimating()
        indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        return indicator
    }()
    let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.9
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newTitle: String = "InstaFilter"
        title = newTitle
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))

        currentFilter = CIFilter(name: "CITwirlDistortion")
        
    }
    @objc private func importPicture() {
        startLoadingAnimation()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let picker = UIImagePickerController()
            picker.allowsEditing = true
            picker.delegate = self
            self.present(picker, animated: true) {
                self.stopLoadingAnimation()
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        currentImage = image
        guard let currentImage = currentImage else { return }
        
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
        stopLoadingAnimation()
        
    }
    
    @IBAction func changeFilter(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
        CIFilterName.allCases.forEach { filter in
                  let action = UIAlertAction(title: filter.stringName, style: .default, handler: { _ in
                      self.set(filter: filter)
                  })
                  alertController.addAction(action)
              }
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        present(alertController, animated: true)
    }
    
    @IBAction func save(_ sender: UIButton) {
        guard let image = imageView.image else {
            let alertController = UIAlertController(title: "Error", message: "Please selct an image", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Ok", style: .destructive))
            present(alertController, animated: true)
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError: contextInfo:)),nil)
    }
    
    @IBAction func intensityChanger(_ sender: Any) {
        applyProcessing()
    }
    
    private func applyProcessing() {
        
       guard let currentImage = currentImage else { return }
        guard let currentFilter = currentFilter else { return }
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey){
            currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey){
            currentFilter.setValue(intensity.value * 200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey)
        }
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let processedImage = UIImage(cgImage: cgImage)
            imageView.image = processedImage
        }
    }
    
    private func set(filter: CIFilterName) {
        currentFilter = CIFilter.make(filter)
        applyProcessing()
    }
}
enum CIFilterName :String, CaseIterable {
    case sepiaTone
    case bumpDistortion
    case gaussianBlur
    case pixellate
    case twirlDistortion
    case unsharpMask
    case vignette
}
extension CIFilterName {
    var stringName: String {
        "CI\(self.rawValue.capitalized)"
    }
}

extension CIFilter {
    static func make(_ filterName: CIFilterName) -> CIFilter? {
        guard CIFilter.filterNames(inCategories: []).contains(filterName.stringName) else { return nil }
        #warning("Problem: Here the return value is nil")
        return CIFilter(name: filterName.stringName)
    }
}


extension ViewController {
    @objc private func startLoadingAnimation() {
        
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        loadingActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(blurEffectView)
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(loadingActivityIndicator)
        NSLayoutConstraint.activate([
            
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingActivityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingActivityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    private func stopLoadingAnimation() {
        blurEffectView.removeFromSuperview()
        loadingActivityIndicator.removeFromSuperview()
    }
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error =  error {
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        } else {
            let alertController = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alertController, animated: true)
        }
    }
}


