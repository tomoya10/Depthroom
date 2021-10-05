//
//  myProfileEditViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/09.
//

import UIKit
import Firebase
import FirebaseStorageUI

class myProfileEditViewController: UIViewController,UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    @IBOutlet weak var myUserNameLabel: UITextField!
    @IBOutlet weak var myProfileImage: UIImageView!
    @IBOutlet weak var myProfileContent: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        database = Firestore.firestore()
        storage = Storage.storage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        myUserNameLabel.text = me.userName
        myProfileContent.text = me.description
        
        if let icon = me.icon{
            let storageRef = icon
            //URL型に代入
            if let photoURL = URL(string: storageRef){
                do{
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    self.myProfileImage.image = image
                }
                catch{
                    print("error")
                    return
                }
            }
        }else{
            //画像を表示
            let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("users").child("profileImage").child("\(me.userID!).jpg")
            myProfileImage.sd_setImage(with: storageRef)
        }
    }
    
    @IBAction func editComplete(_ sender: Any) {
        
            let newUserNameLabel = myUserNameLabel.text!
            let newUserProfile = myProfileContent.text!
            
            if newUserNameLabel.isEmpty != true, let image = myProfileImage.image{
            
                //プロフィール画像を保存
                let data = image.jpegData(compressionQuality: 1.0)
                self.sendProfileImageData(data: data!)
                //ユーザネーム・プロフィールをusersに保存
                let meRef = database.collection("users").document(me.userID)
                meRef.setData([
                    "userName": newUserNameLabel,
                    "description": newUserProfile
                ], merge: true)
                            
                self.dismiss(animated: true, completion: nil)
            }
        }
    
    @IBAction func cancelEdit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapImageView(_ sender: Any) {
        showAlert()
    }
    
    func doCamera(){
        
        let sourceType:UIImagePickerController.SourceType = .camera
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.allowsEditing = true
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func doAlbum(){
        
        let sourceType:UIImagePickerController.SourceType = .photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let cameraPicker = UIImagePickerController()
            cameraPicker.allowsEditing = true
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if info[.originalImage] as? UIImage != nil{
                
                let selectedImage = info[.originalImage] as! UIImage
                myProfileImage.image = selectedImage
                picker.dismiss(animated: true, completion: nil)
            
            }
    }
        
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
        
        //アラート
    func showAlert(){
        
        let alertController = UIAlertController(title: "選択", message: "どちらを使用しますか?", preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "カメラ", style: .default) { (alert) in
            
            self.doCamera()
            
        }
        let action2 = UIAlertAction(title: "アルバム", style: .default) { (alert) in
            
            self.doAlbum()
            
        }

        let action3 = UIAlertAction(title: "キャンセル", style: .cancel)
        
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func sendProfileImageData(data:Data){
        
        let image = UIImage(data: data)
        let profileImage = image?.jpegData(compressionQuality: 0.1)
        
//        let imageRef = Storage.storage().reference().child("profileImage")
        let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("users").child("profileImage").child("\(me.userID!).jpg")
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        if profileImage != nil {
            
            storageRef.putData(profileImage!, metadata: metaData) { (metaData, error) in
                
                if error != nil {
                    print("error: \(error!.localizedDescription)")
                    return
                }
                storageRef.downloadURL(completion: { (url, error) in
                    
                    if error != nil{
                        print("error: \(error!.localizedDescription)")
                        return
                    }
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    
                    if let photoURL = URL(string: url!.absoluteString){
                        changeRequest?.photoURL = photoURL
                        
                        //名前などの更新の前にアイコンに対してurlをstringで保存(更新)する
                        self.database.collection("users").document(self.me.userID).updateData([
                            "icon": url!.absoluteString
                        ])
                    }
                    //ここちょっと自信がないです
                    changeRequest?.commitChanges(completion: nil)
                    
                })
            }
            
        }
    }
}
