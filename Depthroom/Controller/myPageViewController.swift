//
//  myPageViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/06.
//

import UIKit
import Firebase
import FirebaseStorageUI

class myPageViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    
    var flg:Bool = true //フォロー解除用
    //自分のマイページだけではなく、他人のマイページも兼ねているためmeではなく、userで
    var user: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    var postArray:[Post] = []
    var followerAraay:[AppUser] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myUserNameLabel: UILabel!
    @IBOutlet weak var myProfileImage: UIImageView!
    @IBOutlet weak var profileContent: UILabel!
    @IBOutlet weak var profileEdit: UIButton!
    @IBOutlet weak var doFollow: UIButton!
    @IBOutlet weak var buttonToChat: UIButton!
    @IBOutlet weak var buttonToLogout: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        myProfileImage.layer.cornerRadius = 65.0
        
        //自分のマイページでなかったら、編集への遷移を防ぐ
        if auth.currentUser?.uid != user.userID{
            profileEdit.isHidden = true
        }
        //自分自身をフォローできないようにする
        if auth.currentUser?.uid == user.userID{
            doFollow.isHidden = true
            buttonToChat.isHidden = true
        }
        
        //自分のマイページでなかったら、ログアウトはさせない
        if auth.currentUser?.uid != user.userID{
            buttonToLogout.isHidden = true
        }
//        let ids = database.collection("users").document(user.userID)
//        if auth.currentUser?.uid != user.userID{
//            
//        }
        //ユーザネーム・フォロー周りの情報を表示
        database.collection("users").document(user.userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.user = AppUser(data: data)
                
                //フォロー情報を配列に格納
                if let follow = data["follow"] as? [String:Any]{
                    for follow in follow.values{
                        let userInfo = AppUser(data: follow as! [String:Any])
                        if userInfo.userID != self.auth.currentUser?.uid {
//                            self.doFollow.setTitle("フォローする", for: .normal)
//                            self.flg=true
                            print()
                        }else{
                            self.doFollow.setTitle("フォロー解除", for: .normal)
                            self.flg=false
                        }
                        //                        self.followerAraay.append(userInfo)
                    }
                }
            }
        }
    }
            
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            //今回はナビゲーションバーを表示
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            
            //ユーザネームと自己紹介を表示
            database.collection("users").document(user.userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                    self.user = AppUser(data: data)
                    self.myUserNameLabel.text = self.user.userName
                    self.profileContent.text = self.user.description
                    
                    //アイコンの情報を渡して画像を表示
                    if let icon = self.user.icon{
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
                        //プロフィール画像を表示
                        let storageRef = self.storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(self.user.userID!).jpg")
                        
                        //キャッシュを消して画像を表示
                        SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                        self.myProfileImage.sd_setImage(with: storageRef)
                    }
                }
            }
            
            //自身の投稿内容をFireStoreから取得
            database.collection("posts").whereField("senderID", isEqualTo: user.userID!).getDocuments { (snapshot, error) in
                if error == nil, let snapshot = snapshot{
                    self.postArray = []
                    for document in snapshot.documents{
                        let data = document.data()
                        let post = Post(data: data)
                        self.postArray.append(post)
                    }
                    self.tableView.reloadData()
                }
            }
        }
        
        
        
        //プロフィール編集画面へ遷移
        @IBAction func profileEdit(_ sender: Any) {
            performSegue(withIdentifier: "profileEdit", sender: user)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "profileEdit"{
                let nextViewController = segue.destination as! myProfileEditViewController
                nextViewController.me = user
            }
            
            if segue.identifier == "myPostShow"{
                let nextViewController = segue.destination as! postShowViewController
                nextViewController.post = Post(data: ["postID": postArray[sender as! Int].postID!])
                nextViewController.senderID = self.postArray[sender as! Int].senderID
            }
            
            if segue.identifier == "follows"{
                let nextViewController = segue.destination as! followsViewController
                nextViewController.user = AppUser(data: ["userID": user.userID!])
            }
            
            if segue.identifier == "directMessage"{
                let nextViewController = segue.destination as! directMessageViewController
                nextViewController.user = AppUser(data: ["userID": user.userID!])
            }
        }
        
        //フォローの処理
        @IBAction func doFollow(_ sender: Any) {
            if(flg){
                
                flg=false
                //フォローするからフォロー解除へタイトル変更
                doFollow.setTitle("フォロー解除", for: .normal)
                
                //フォローした人(自分)の follow に相手の情報を保存
                let me = database.collection("users").document(auth.currentUser!.uid)
                let otherInfo = [
                    "userID": user.userID
                ]
                me.updateData([
                    "follow.\(user.userID!)": otherInfo
                ])
                
                //フォローされた人(相手)の follower に自分の情報を保存
                let you = database.collection("users").document(user.userID)
                let meInfo = [
                    "userID": auth.currentUser?.uid
                ]
                you.updateData([
                    "follower.\(auth.currentUser!.uid)": meInfo
                ])
                
            }
            else{
                flg = true
                //フォロー解除からフォローするへタイトル変更
                doFollow.setTitle("フォローする", for: .normal)
                //フォロー解除した人(自分)からフォロー解除された人の情報を follow から削除
                let me = database.collection("users").document(auth.currentUser!.uid)
                
                me.updateData([
                    "follow.\(user.userID!)": FieldValue.delete()
                ])
                
                //フォロー解除された人(相手)からフォロー解除した人の情報を follower から削除
                let you = database.collection("users").document(user.userID)
                
                you.updateData([
                    "follower.\(auth.currentUser!.uid)": FieldValue.delete()
                ])
            }
        }
        
        
        
        //フォローしている人の画面に遷移
        @IBAction func buttonToFollowing(_ sender: Any) {
            performSegue(withIdentifier: "follows", sender: user)
        }
        
        //DMによるチャット画面への遷移
        @IBAction func buttonToChat(_ sender: Any) {
            performSegue(withIdentifier: "directMessage", sender: user)
            
        }
        
        //ログアウトボタン→登録の画面へ遷移
        @IBAction func buttonToLogout(_ sender: Any) {
            try? auth.signOut()
            //let newRegisterViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newRegister") as! newRegisterViewController
            //present(newRegisterViewController, animated: true, completion: nil)
            performSegue(withIdentifier: "logout", sender: nil)
        }
        
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            //投稿詳細画面への遷移
            performSegue(withIdentifier: "myPostShow", sender: indexPath.row)
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return postArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            
            cell.textLabel?.text = postArray[indexPath.row].content
            
            //senderIDよりAppUser情報をFireStoreから取得
            //正直ここはPostから参照する必要はないが、今後必要になる時に備えて
            database.collection("users").document(postArray[indexPath.row].senderID).getDocument { (snapshot, error) in
                
                if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                    let appUser = AppUser(data: data)
                    cell.detailTextLabel?.text = appUser.userName
                }
            }
            return cell
        }
    }
