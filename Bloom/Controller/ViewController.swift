//
//  ViewController.swift
//  Bloom
//
//  Created by Su Min Kim on 7/9/20.
//  Copyright © 2020 Su Min Kim. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import RealmSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let realm = try! Realm()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
        
    var flowerImageURL: String?
    var flowerDescription: String?
    
    var totalFlowers: Results<Flower>?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera // user can take an image
        imagePicker.allowsEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpButton()
    }

    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Button with Flower Count
    func setUpButton() {
        
        getFlowers()
        
        let count = totalFlowers?.count ?? 0
        
        let button =  UIButton(type: .custom)
        button.setImage(UIImage(named: "BloomCount"), for: .normal)
        button.addTarget(self, action: #selector(self.navigateToTable), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 90, height: 30)
        button.imageEdgeInsets = UIEdgeInsets(top: -1, left: -30, bottom: 1, right: 30)
        
        let label = UILabel(frame: CGRect(x: 27, y: 5, width: 35, height: 20))
        label.font = UIFont(name: "Arial-BoldMT", size: 16)
        label.text = String(count)
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor =  .clear
        button.addSubview(label)
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @objc func navigateToTable() {
        performSegue(withIdentifier: "homeToTable", sender: self)
    }
    
    // MARK: - Image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
//            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Unable to convert image to CI Image.")
            }
            
            detect(image: ciimage)
        }
        
        var textField = UITextField()
        let alert = UIAlertController(title: "What's that flower?",
                                      message: "Try to guess what flower this is!",
                                      preferredStyle: .alert)

        let action = UIAlertAction(title: "Guess!", style: .default) { (action) in
            
            self.imagePicker.dismiss(animated: true, completion: {
                
                if let guess = textField.text, let answer = self.navigationItem.title {
                    if guess.lowercased() == answer.lowercased() {
                        let newFlower = Flower()
                        newFlower.name = answer
                        newFlower.imageURL = self.flowerImageURL ?? ""
                        newFlower.flowerDescription = self.flowerDescription ?? ""
                        self.addFlower(flower: newFlower)
                    }
                }
            })
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Flower Name"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        self.imagePicker.present(alert, animated: true, completion: nil)

    }
    
    // MARK: - CoreML
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot convert model.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    // MARK: - Wiki API Call
    func requestInfo(flowerName: String) {
            
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).validate().responseJSON { (response) in
            
            switch response.result {
                case .success(let data):
                    let flowerJSON: JSON = JSON(data)
//                    let flowerJSON: JSON = JSON(response.value!)
                    let pageid = flowerJSON["query"]["pageids"][0].stringValue
                    let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                    let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                    
                    self.flowerImageURL = flowerImageURL
                    self.flowerDescription = flowerDescription
                    self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                    self.label.text = flowerDescription
                default:
                    print("Error fetching flower data.")
            }
        }
    }
    
    // MARK: - Realm Data Manipulation Methods
    func addFlower(flower: Flower) {
        do {
            try realm.write {
                realm.add(flower)
                setUpButton()
            }
        } catch {
            print(error)
        }
    }
    
    func getFlowers() {
        totalFlowers = realm.objects(Flower.self)
    }
}

