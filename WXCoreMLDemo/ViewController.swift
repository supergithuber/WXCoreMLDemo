//
//  ViewController.swift
//  WXCoreMLDemo
//
//  Created by HFY on 2019/3/14.
//  Copyright © 2019年 wuxi. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.lightGray
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var pickButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("选一张照片", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var informationTextView : UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.yellow
        textView.alpha = 0.5
        textView.textColor = UIColor.red
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView(){
        view.addSubview(imageView)
        view.addSubview(pickButton)
        view.addSubview(informationTextView)
        ///
        let viewWidth = view.bounds.width
        imageView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewWidth * 4 / 3)
        ///
        pickButton.frame.size = CGSize(width: 100, height: 50)
        pickButton.center.x = view.center.x
        pickButton.center.y = (viewWidth * 4 / 3) + 25
        ///
        let textViewHeight:CGFloat = 100
        self.informationTextView.frame = CGRect(x: 0, y: self.view.frame.size.height - textViewHeight, width: self.view.frame.size.width, height: textViewHeight)
        view.addSubview(informationTextView)
        
    }

    private func appendTextToTextView(text: String)
    {
        DispatchQueue.main.async {
            var originText = self.informationTextView.text
            originText?.append("\n" + text)
            self.informationTextView.text = originText
            self.informationTextView.scrollRangeToVisible(NSMakeRange((self.informationTextView.text.lengthOfBytes(using: String.Encoding.utf8)), 1))
        }
        
    }
    
    @objc func pickImage(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true) {
            
        }
    }
    
    private func progressImage(image: UIImage){
        self.informationTextView.text = ""
        self.appendTextToTextView(text: "识别中......")
        
        let mobileNetModel = MobileNet.init()
        do {
            //生成coreMLModel
            let coreMLModel = try VNCoreMLModel.init(for: mobileNetModel.model)
            //生成请求
            let coreMLRequest = VNCoreMLRequest.init(model: coreMLModel) { [weak self](request, error) in
                if let error = error {
                    self?.appendTextToTextView(text: "识别失败:\(error)")
                }else {
                    let results = request.results as! [VNClassificationObservation]
                    for result in results{
                        let confidence = result.confidence //float
                        let identifier = result.identifier //string
                        if confidence > 0.1{
                            self?.appendTextToTextView(text: "物品可能是:\(identifier),概率为:\(confidence) \n")
                        }
                        
                    }
                    
                }
            }
            //请求handler
            let imageRequestHandler = VNImageRequestHandler.init(cgImage: image.cgImage!, options: [:])
            //发起请求
            try imageRequestHandler.perform([coreMLRequest])
            
        }catch let error {
            self.appendTextToTextView(text: "失败：\(error)")
        }
        
            
        
        
    }
    
    /// delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageView.image = image
            self.progressImage(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

