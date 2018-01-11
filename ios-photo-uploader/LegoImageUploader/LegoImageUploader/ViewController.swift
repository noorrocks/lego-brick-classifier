//
//  ViewController.swift
//  LegoImageUploader
//
//  Created by Art Gillespie on 1/10/18.
//  Copyright © 2018 tapsquare. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User?
    
    func firebaseDidAuthenticate() {
        // getImageCount()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "secrets", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            let auth = Auth.auth()
            if let u = auth.currentUser  {
                print("Already signed in! \(u.providerData[0].email!)")
                self.user = u
                firebaseDidAuthenticate()
            } else {
                let email = dict.value(forKey: "email")! as! String
                let password = dict.value(forKey: "password")! as! String
                auth.signIn(withEmail: email, password: password, completion: { (u: User?, e: Error?) in
                    if let error = e {
                        print("Error logging in! \(error)")
                    } else if let user = u {
                        print("Logged in! \(user.providerData[0].email!)")
                        self.user = user
                        self.firebaseDidAuthenticate()
                    } else {
                        print("Both user and error are nil :-(")
                    }
                })
            }
        } else {
            print("Couldn't lead secrets plist")
        }
    }

    @IBAction func handlePhotoButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("Can't pick from camera")
            return
        }
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getImageCount() {
        // no way to enumerate objects in a folder in the firebase api
        // recommended approach is to track metadata in firebase database
        let storage = Storage.storage()
        let storageRef = storage.reference(withPath: "images/brick_2x2_white")
        storageRef.getMetadata { (metadata, error) in
            guard let metadata = metadata else {
                print("error fetching metadata: \(error!)")
                return
            }
            print("images folder metadata: \(metadata)")
        }
    }
    
    func uploadImage(_ image: UIImage, type: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference(withPath: "images/\(type)/\(UUID().uuidString)")
        guard let data = UIImageJPEGRepresentation(image, 1.0) else {
            print("couldn't get jpg representation")
            return
        }
        let uploadTask = storageRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                print("Error uploading image: \(error!)")
                return
            }
            print("Upload OK! \(metadata)")
        }
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            print("Progress : \(percentComplete)")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        let type = info[UIImagePickerControllerMediaType] as! String
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        print("Image Picked! \(type)")
        uploadImage(image, type: "test")
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image picker canceled!")
    }

}

