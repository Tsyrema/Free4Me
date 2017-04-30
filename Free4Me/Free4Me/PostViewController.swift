//
//  PostViewController.swift
//  Free4Me
//
//  Created by Madushani Lekam Wasam Liyanage on 4/29/17.
//  Copyright © 2017 Madushani Lekam Wasam Liyanage. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import AVFoundation
import AVKit
import MobileCoreServices

//let name: String
//let image: String
//let category: String
//let ownerId: String
//let borough: String
//let expiration: String

class PostViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var datePickerView: UIDatePicker!
    
    @IBOutlet weak var pickedImageView: UIImageView!
    var imagePickerController: UIImagePickerController!
    
    var capturedImage: UIImage!
    var user: User?
    var databaseRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var userStore: UserStore?
    
    let categories = ["Books", "Furniture", "Tickets", "Electronics", "Other"]
    var pickedCategory: String?
    var pickedDate: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        databaseRef = FIRDatabase.database().reference()
        userStore = UserStore()
        
    }
    
    func postToFirebase() {
        
        let postRef = self.databaseRef.childByAutoId()
        let storage = FIRStorage.storage()
        let storageRef = storage.reference(forURL: "gs://free4me-49bcf.appspot.com")
        let imageNameRef = storageRef.child("images/\(postRef.key)")
        
        let metadata = FIRStorageMetadata()
        metadata.cacheControl = "public,max-age=300"
        metadata.contentType = "image/jpeg"
        
        if let userId = FIRAuth.auth()?.currentUser?.uid {
            
            if capturedImage != nil {
                let jpeg = UIImageJPEGRepresentation(capturedImage, 0.5)
                
                let _ = imageNameRef.put(jpeg!, metadata: metadata, completion: { (metadata, error) in
                    guard metadata != nil else {
                        print("put error: \(String(describing: error?.localizedDescription))")
                        return
                    }
                })
                
            }
            
            var expiration = "N/A"
            if let name = nameTextField.text,
                let category = pickedCategory,
                let pickedDate = pickedDate {
                expiration = pickedDate
                userStore?.getUser(id: userId) { (user) in
                    
                    
                    
                    let freebieDict = ["name": name, "image": imageNameRef, "category": category, "ownerId": userId, "borough": user.borough, "expiration":expiration] as [String:Any]
                    let postDict = ["name": "", "image": imageNameRef, "category": category, "expiration":expiration] as [String:Any]
                    self.databaseRef.child("freebies").childByAutoId().setValue(freebieDict)
                    self.databaseRef.child((FIRAuth.auth()?.currentUser?.uid)!).setValue(postDict)
                    
                }
                
            }
            else {
                print("not completed")
            }
        }
        else {
            print("not signed in")
            let alertController = showAlert(title: "Not signed in!", message: "You need to sign in to post an item. Would you like to be directed to the login page?", useDefaultAction: false)
            
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                //go the login page
                
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                
                self.dismiss(animated: true, completion: nil)
                
            }))
            self.present(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    func postImage(postRef: String, imageNameRef: String) {
        
        
        
    }
    
    
    @IBAction func postButtonTapped(_ sender: UIButton) {
        
        self.postToFirebase()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickedCategory = categories[row]
        
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        switch info[UIImagePickerControllerMediaType] as! String {
        case String(kUTTypeImage):
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.capturedImage = image
                pickedImageView.image = nil
                pickedImageView.backgroundColor = .clear
                pickedImageView.contentMode = .scaleAspectFit
                pickedImageView.image = capturedImage
            }
            
        default:
            print("Bad Media Type")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        pickedDate = String(describing: datePickerView.date)
    }
    
    @IBAction func pickImageTapped(_ sender: UIButton) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .currentContext
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [String(kUTTypeImage)]
        
        self.imagePickerController = imagePickerController
        self.present(imagePickerController, animated: true, completion: nil)
        

    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
public func showAlert(title: String, message: String?, useDefaultAction: Bool) -> UIAlertController {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    if useDefaultAction {
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
    }
    
    return alertController
}


