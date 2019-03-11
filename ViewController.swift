//
//  ViewController.swift
//  WhatPet
//
//  Created by Bruno Magalhães on 08/01/19.
//  Copyright © 2019 Cybernetic Company of Milky Way. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let wikiURL = "https://en.wikipedia.org/w/api.php"
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textBox: UITextView!
    
    
    
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickerImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let convertedCIImage = CIImage(image: userPickerImage) else {fatalError("Could not convert to UIImage into CIImage.")}
            
            imageView.image = userPickerImage
            
            detect(image: convertedCIImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: PetImageClassifier().model) else {fatalError("Cannot import model.")}
        
        let request = VNCoreMLRequest(model: model) {(request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            
            self.navigationItem.title = classification?.identifier.capitalized
            self.requestInfo(petSpecie: (classification?.identifier)!)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(petSpecie: String) {
        
        let parameters : [String:String] = [
            
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : petSpecie,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
            
        ]
        
        Alamofire.request(wikiURL, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess {
                print("Got the wikipedia info.")
                print(response)
                
                let petJSON: JSON = JSON(response.result.value!)
                
                let pageid = petJSON["query"]["pageids"][0].stringValue
                
                let petDescription = petJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let petImageURL = petJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: petImageURL))
                
                self.textBox.text = petDescription
            }
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
}

