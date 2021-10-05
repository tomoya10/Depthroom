//
//  newRoomViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/08.
//

import UIKit
import Firebase
import FirebaseStorageUI

class newRoomViewController2: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var me: AppUser!
    //reserveはラベル表示用
    var reserve: String!
    var database: Firestore!
    var storage: Storage!
    //ルームに招待する人のIDを格納する配列
    var inviteSelectUser: [AppUser] = []
    //招待者の情報をFireStoreに保存する際に使われる
    var inviteMap: [String:Any] = [:]
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UITextField!
    @IBOutlet weak var roomDescriptionLabel: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reserveLabel: UILabel!
    
    //roomsのmembersに自身の情報を登録させる際、紹介文が空の場合の対策
    var meDescription = ""
    //"example"は仮置き
    var roomID = "example"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        let checkModel = CheckPermission()
        checkModel.showCheckPermission()
        roomNameLabel.delegate = self
        roomDescriptionLabel.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        //カスタムのセルを登録
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        imageView.layer.cornerRadius = 60
        
        if reserve.isEmpty == true{
            reserveLabel.isHidden = true
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reserveLabel.text = "予約：\(reserve!)"
    }
    //createボタンを押した時のアクション
    @IBAction func createRoom(_ sender: Any) {
        let roomName = roomNameLabel.text!
        let roomDescription = roomDescriptionLabel.text!
        let image = imageView.image!
        
        //無闇にFireStoreに接続させないためにif 文で空かどうかを判断する
        if roomName.isEmpty != true && roomDescription.isEmpty != true{
            //ownerのユーザの名前を登録する必要があるため、クロージャを用いてnameを取得し、ルームと招待者を登録している
            database.collection("users").document(me.userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    self.me = AppUser(data: data)
                    let meName = self.me.userName
                    let meIcon = self.me.icon
                    //description は空の場合があり得るため
                    self.meDescription = self.me.description
                    //ルームと招待者の登録を行う
                    self.registerRoomAndInvitation(roomName: roomName, roomDescription: roomDescription, image: image, meName: meName!, meIcon: meIcon!, meDescription: self.meDescription)
                }
            }
        }
        //全て登録したら画面遷移
       // self.dismiss(animated: true, completion: nil)
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func cancelRoomCreate(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    //createRoomアクション時の登録に関する処理
    func registerRoomAndInvitation(roomName: String, roomDescription: String, image: UIImage, meName: String, meIcon: String, meDescription: String){
        
        if roomName.isEmpty != true && roomDescription.isEmpty != true && inviteSelectUser.count > 0{
            //ここでif文で分岐　内容は部屋の予約しているかどうか
            //予約していた場合は、visibleをfalseに
            //予約していない場合は、visibleをtrueにupdateAtを追加、upadateAtはcreatedAtと同じで
            if reserve.isEmpty != true{
                
                let date = dateFromString(string: reserve, format: "y年MM月dd日 HH:mm:ss")
                
                let saveRoom = database.collection("rooms").document()
                saveRoom.setData([
                    "roomID": saveRoom.documentID,
                    "roomName": roomName,
                    "description": roomDescription,
                    "ownerID": me.userID!,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": Timestamp(date: date),
                    "visible": false,
                    "invitation": [],
                    "members": [
                        me.userID: [
                            "userID": me.userID,
                            "userName": meName,
                            "description": meDescription,
                            "icon": meIcon
                        ]
                    ]
                ]){err in
                    if let err = err{
                        print("Error writing document: \(err)")
                    }else{
                        print("Document successfully written!")
                    }
                }
                
                
                //招待者の情報を"invitation"に保存
                for invite in inviteSelectUser{
                    inviteMap["\(invite.userID!)"] = [
                        "userID": invite.userID,
                        "userName": invite.userName,
                        "description": invite.description,
                        "icon": invite.icon
                    ]
                }
                saveRoom.updateData([
                    "invitation": inviteMap
                ])
                
                
//                //選択したユーザは招待扱いとなり、invitation 以下にユーザデータを保存
//                let saveInvitation = database.collection("invitation").document(saveRoom.documentID)
//                var userDoc: [String: Any] = [
//                    "users": []
//                ]
//
//                //2021/08/13解決!
//                //配列を回して値を一時的にusers, existingUsersに格納するString:Anyのため
//                for select in inviteSelectUserID{
//
//                    let users: [String:Any] = [
//                        "userID": select.userID!,
//                        // "userName": select.userName!
//                    ]
//
//                    var existingUsers = userDoc["users"] as? [[String: Any]] ?? [[String: Any]]()
//                    existingUsers.append(users)
//                    userDoc["users"] = existingUsers
//                }
//                //userDocを保存
//                saveInvitation.setData(userDoc){err in
//                    if let err = err{
//                        print("Error writing document: \(err)")
//                    }else{
//                        print("Document successfully written!")
//                    }
//                }
                
                //roomID(documentID)を変数に格納、ルームのサムネイル画像のファイル名に使用する
                roomID = saveRoom.documentID
                
                //プロフィール画像を保存
                let data = image.jpegData(compressionQuality: 1.0)
                self.sendProfileImageData(data: data!)
                
                //ここから下は予約していない時の処理
            }else{
                
                let saveRoom = database.collection("rooms").document()
                saveRoom.setData([
                    "roomID": saveRoom.documentID,
                    "roomName": roomName,
                    "description": roomDescription,
                    "ownerID": me.userID!,
                    "visible": true,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "members": [
                        me.userID: [
                            "userID": me.userID,
                            "userName": meName,
                            "description": meDescription,
                            "icon": meIcon
                        ]
                    ]
                ]){err in
                    if let err = err{
                        print("Error writing document: \(err)")
                    }else{
                        print("Document successfully written!")
                    }
                }
                
                //招待者の情報を"invitation"に保存
                for invite in inviteSelectUser{
                    inviteMap["\(invite.userID!)"] = [
                        "userID": invite.userID,
                        "userName": invite.userName,
                        "description": invite.description,
                        "icon": invite.icon
                    ]
                }
                saveRoom.updateData([
                    "invitation": inviteMap
                ])
                
//                //選択したユーザは招待扱いとなり、invitation 以下にユーザデータを保存
//                let saveInvitation = database.collection("invitation").document(saveRoom.documentID)
//                var userDoc: [String: Any] = [
//                    "users": []
//                ]
//                //2021/08/13解決!
//                //配列を回して値を一時的にusers, existingUsersに格納するString:Anyのため
//                for select in inviteSelectUserID{
//
//                    let users: [String:Any] = [
//                        "userID": select.userID!,
//                        // "userName": select.userName!
//                    ]
//
//                    var existingUsers = userDoc["users"] as? [[String: Any]] ?? [[String: Any]]()
//                    existingUsers.append(users)
//                    userDoc["users"] = existingUsers
//                }
//                //userDocを保存
//                saveInvitation.setData(userDoc){err in
//                    if let err = err{
//                        print("Error writing document: \(err)")
//                    }else{
//                        print("Document successfully written!")
//                    }
//                }
                
                //roomID(documentID)を変数に格納、ルームのサムネイル画像のファイル名に使用する
                roomID = saveRoom.documentID
                
                //プロフィール画像を保存
                let data = image.jpegData(compressionQuality: 1.0)
                self.sendProfileImageData(data: data!)
            }
        }
    }
    
    func dateFromString(string: String, format: String) -> Date{
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter.date(from: string)!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return mutualFollowArray.count
        return inviteSelectUser.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
        
        database.collection("users").document(inviteSelectUser[indexPath.row].userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                let appUser = AppUser(data: data)
                cell.userNameLabel.text = appUser.userName
                
                //ユーザのプロフィール画像を取得・表示
                if let icon = self.me.icon{
                    let storageRef = icon
                    //URL型に代入
                    if let photoURL = URL(string: storageRef){
                        do{
                            let data = try Data(contentsOf: photoURL)
                            let image = UIImage(data: data)
                            cell.profileImageView.image = image
                        }
                        catch{
                            print("error")
                            return
                        }
                    }
                }else{
                    let storageRef = self.storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(self.inviteSelectUser[indexPath.row].userID!).jpg")
                    
                    //キャッシュを消している
                    SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                    cell.profileImageView.sd_setImage(with: storageRef)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //今回(2021/0812)は95に設定
        return 95
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
                imageView.image = selectedImage
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
        
        //FireStoreからルームのIDを取得、storageのルームのサムネイル画像の名前に使用(roomID)
        //ルーム画像の保存先の指定
        let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("rooms").child("roomThumbnail").child("\(roomID).jpg")
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
                        
                        //ルーム名などの前にアイコンのurlをstringで保存する
                        self.database.collection("rooms").document(self.roomID).setData([
                            "icon": url!.absoluteString
                        ], merge: true)
                    }
                    //ここちょっと自信がないです
                    changeRequest?.commitChanges(completion: nil)
                    
                })
            }
            
        }
    }
}

extension newRoomViewController2: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
