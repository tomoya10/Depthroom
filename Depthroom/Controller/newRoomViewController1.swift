//
//  roomReservationViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/28.
//

import UIKit
import Firebase
import FirebaseStorageUI

class newRoomViewController1: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var database: Firestore!
    var storage: Storage!
    //自分がfollowing, 相手がfollowedの配列
    //var followingArray:[Follow] = []
    //自分がfollowed, 相手がfollowingの配列
    //var followedArray:[Follow] = []
    //相手が自分をフォローしており、相手の情報を格納
    var followerArray: [AppUser] = []
    //自分と相互フォローの人の配列
    //var mutualFollowArray:[String] = []
    //ルームに招待する人のIDを格納する配列
    var inviteSelectUserID: [AppUser] = []
    var datePicker: UIDatePicker = UIDatePicker()
    
    @IBOutlet weak var timeLabel: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        timeLabel.delegate = self
        
        //カスタムのセルを登録
        tableView.register(UINib(nibName: "roomCreateCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        //タップした時にキーボードではなく、datePicker を表示
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.datePickerMode = .dateAndTime
        datePicker.timeZone = NSTimeZone.local
        //現在時刻より前を選択することはできない
        datePicker.minimumDate = Date()
        //現在時刻より一ヶ月後以降を選択することはできない
        datePicker.maximumDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        //datePicker.locale = Locale.current
        datePicker.locale = Locale(identifier: "ja_JP")
        timeLabel.inputView = datePicker
        //時間を決定するためのボタンを配置
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
         let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
         let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
         toolbar.setItems([spacelItem, doneItem], animated: true)
        timeLabel.inputView = datePicker
        timeLabel.inputAccessoryView = toolbar
        
        // デフォルト日付
        //let formatter = DateFormatter()
        //formatter.dateFormat = "yyyy-MM-dd"
        //datePicker.date = formatter.date(from: "2020-8-12")!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //fireStore内の"follows"からデータを取得
        //今回は相互フォロー状態の人のみを招待できる
        //2021/08/11日現在、招待機能は実装できていない
        //まずfollowingIDのフィルターで自分を見つける
//        database.collection("follows").whereField("followingID", isEqualTo: me.userID!).getDocuments { (snapshot, error) in
//            if error == nil, let snapshot = snapshot{
//                self.followingArray = []
//                for document in snapshot.documents{
//                    let data = document.data()
//                    let follows = Follow(data: data)
//                    self.followingArray.append(follows)
//                }
//            }
//        }
        
        //followedIDのフィルターで自分を見つける
//        database.collection("follows").whereField("followedID", isEqualTo: me.userID!).getDocuments { (snapshot, error) in
//            if error == nil, let snapshot = snapshot{
//                self.followedArray = []
//                for document in snapshot.documents{
//                    let data = document.data()
//                    let follows = Follow(data: data)
//                    self.followedArray.append(follows)
//                }
//                self.tableView.reloadData()
//            }
//        }
        
        //自分をフォローしてくれているユーザを配列に格納
        database.collection("users").document(me.userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                if let follower = data["follower"] as? [String:Any]{
                    for follower in follower.values{
                        let userInfo = AppUser(data: follower as! [String:Any])
                        self.followerArray.append(userInfo)
                    }
                    self.tableView.reloadData()
                }
            }
        }
        
        //followingArrayとfollowedArrayから自分がフォローした人とフォローされた人を見つける
        //mutualFollowArrayにfollowedArrayをappendしているため、FollowingIDが相手のユーザID
        //for i in 0..<(followingArray.count){
          //  print(i)
            //for j in 0..<(followedArray.count){
              //  print(followedArray[j].followingID!)
                //if followedArray[j].followingID == followingArray[i].followedID{
                  //  mutualFollowArray.append(followedArray[j].followingID)
                    //print("追加された")
                    //if mutualFollowArray.count == 0{
                      //  print("入っていない")
                    //}else{
                      //  print("入っている")
                   // }
                //}else {
                  //  print("入らない")
               // }
           // }
       // }
        //tableView.reloadData()
    }
    
    @IBAction func nextButton(_ sender: Any) {
            performSegue(withIdentifier: "completeCreateRoom", sender: me)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "completeCreateRoom"{
            let nextViewController = segue.destination as! newRoomViewController2
            nextViewController.inviteSelectUser = inviteSelectUserID
            nextViewController.me = AppUser(data: ["userID": me.userID!])
            //reserveはテキストとして
            nextViewController.reserve = timeLabel.text
        }
    }
    
    @objc func done() {
         timeLabel.endEditing(true)
         // 日付のフォーマット
         let formatter = DateFormatter()
         formatter.dateFormat = "y年MM月dd日 HH:mm:ss"
        timeLabel.text = "\(formatter.string(from: datePicker.date))"
     }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //チェックを表示
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
        cell.checkImage.isHidden = false
        
        //fireStoreから選択したユーザIDを取得、配列に入れる
        //2021/08/12現在、一度選択したら取り消すことができない
                database.collection("users").document(followerArray[indexPath.row].userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                let appUser = AppUser(data: data)
                //配列に追加
                self.inviteSelectUserID.append(appUser)
                //cellに名前を表示(選択した場合でも必要みたい)
                cell.userNameLabel.text = appUser.userName
                //ユーザのプロフィール画像を取得・表示(セルを選択したときも必要みたい)
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
                    let storageRef = self.storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(self.followerArray[indexPath.row].userID!).jpg")
                    
                    //キャッシュを消している
                    SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                    cell.profileImageView.sd_setImage(with: storageRef)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followerArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCreateCell
        
        database.collection("users").document(followerArray[indexPath.row].userID).getDocument { (snapshot, error) in
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
                    let storageRef = self.storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(self.followerArray[indexPath.row].userID!).jpg")
                    
                    //キャッシュを消している
                    SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                    cell.profileImageView.sd_setImage(with: storageRef)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timeLabel.resignFirstResponder()
    }
}

extension newRoomViewController1: UITextFieldDelegate{
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // キーボード入力や、カット/ペースによる変更を防ぐ
        return false
    }
}
