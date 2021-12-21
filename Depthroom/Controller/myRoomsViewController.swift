//
//  myRoomsViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/03.
//

import UIKit
import Firebase
import FirebaseStorageUI

class myRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var me: AppUser!
    var myName: String!
    var myIcon: String!
    var myDescription: String!
    var database: Firestore!
    var storage: Storage!
    var invitation: [[String: Any]] = []
    @IBOutlet weak var tableView: UITableView!
    var roomArray:[Room] = [] {
        didSet{
            //roomArray配列に変化があった際に呼ばれる
            tableView.reloadData()
        }
    }
    //予約しているルーム配列
    var reserveRoomArray:[Room] = []
    //主に招待されているルームを一覧から選択したときに(タップ時に)、ifで見分ける際に使う
    var invitationArray: [String] = []
    @IBOutlet weak var buttonToMyPage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        
        //カスタムしたセルを登録(roomCell)
        tableView.register(UINib(nibName: "roomCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //クルクル更新します
        configureRefreshControl()
    }
    func configureRefreshControl(){
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl(){
        
        //時間予約に達したら、visibleをtrueにする
        activeRoomFromReserved()
        //ルームの内容に変更があったら、更新する
        
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()  //これを必ず記載すること
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        roomInfo()
        //予約時間に達した部屋を入室可能状態にする(visibleをfalseからtrueに)
        //2021/09/07時間になるとtrueになるが、選択したかったら一度立ち上げ直す必要がある問題
        activeRoomFromReserved()
    }
    
    @IBAction func buttonToMyPage(_ sender: Any) {
        performSegue(withIdentifier: "myPage", sender: me)
    }
    
    @IBAction func buttonToPostIndex(_ sender: Any) {
        performSegue(withIdentifier: "postIndex", sender: me)
    }
    
    @IBAction func buttonToCreateRoom(_ sender: Any) {
        performSegue(withIdentifier: "createRoom", sender: me)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "myPage"{
            let nextViewController = segue.destination as! myPageViewController
            nextViewController.user = AppUser(data: ["userID": me.userID!])
        }
        if segue.identifier == "postIndex"{
            let nextViewController = segue.destination as! postIndexViewController
            nextViewController.me = AppUser(data: ["userID": me.userID!])
        }
        if segue.identifier == "createRoom"{
            let nextViewController = segue.destination as! newRoomViewController1
            nextViewController.me = AppUser(data: ["userID": me.userID!])
        }
        if segue.identifier == "roomChat"{
            let nextViewController = segue.destination as! roomChatViewController
            //ルームのID情報を送る
            nextViewController.room = Room(data: ["roomID": roomArray[sender as! Int].roomID!])
        }
    }
    
    //ユーザの名前の情報を取得し、roomInfoFromFirebaseに渡す
    func roomInfo(){
        database.collection("users").document(me.userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.me = AppUser(data: data)
                
                //アイコンの情報を渡して画像を表示
                if let icon = self.me.icon{
                    let storageRef = icon
                    //URL型に代入
                    if let photoURL = URL(string: storageRef){
                        //data型→image型に代入
                        do{
                            let data = try Data(contentsOf: photoURL)
                            let image = UIImage(data: data)
                            self.buttonToMyPage.setImage(image, for: .normal)
                            //角丸に
                            self.buttonToMyPage.layer.masksToBounds = true
                            self.buttonToMyPage.layer.cornerRadius = 35
                        }
                        catch{
                            print("error")
                            return
                        }
                    }
                    
                }else{
                    //ユーザ詳細のボタンにプロフィール画像を表示
                    //何もなければdefaultを設定
                    //2021/10/01 アイコンのURLをFireStore上に保存する処理が完了したため、以下の文章はいずれ消える
                    
                    let storageRef = self.storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(self.me.userID!).jpg")
                    //キャッシュを消して画像を表示
                    SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
                    storageRef.downloadURL { (url, error) in
                        if error != nil{
                            print("error: \(error!.localizedDescription)")
                            return
                        }
                        //URL型に代入
                        if let photoURL = URL(string: url!.absoluteString){
                            //data型→image型に代入
                            do{
                                let data = try Data(contentsOf: photoURL)
                                let image = UIImage(data: data)
                                self.buttonToMyPage.setImage(image, for: .normal)
                                //角丸に
                                self.buttonToMyPage.layer.masksToBounds = true
                                self.buttonToMyPage.layer.cornerRadius = 35
                            }
                            catch{
                                print("error")
                                return
                            }
                            
                        }
                    }
                }
                
                //ポップアップのために自身の名前を渡す
                self.myName = self.me.userName
                self.myIcon = self.me.icon
                self.myDescription = self.me.description
                //ルームの情報を取得(viewWillAppearとの違いはわからない)
                
                self.roomInfoFromFirebase()
            }
        }
    }
    
    
    //fireStoreからルーム情報を取得するためのメソッド
    func roomInfoFromFirebase(){
        roomArray = []
        invitationArray = []
        
        //自身が所属するルームの内容をFireStoreから取得
        database.collection("rooms").whereField("members.\(me.userID!).userID", isEqualTo: me.userID!).getDocuments { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                for document in snapshot.documents{
                    //自身が所属するルームを配列に追加
                    let data = document.data()
                    let room = Room(data: data)
                    self.roomArray.append(room)
                }
                self.tableView.reloadData()
            }
        }
        
//        //memberが一人のみの場合以下のarrayContainsの手法は使用できないため、専用の検索方法を用意
//        database.collection("rooms").whereField("members.userID", isEqualTo: me.userID!).getDocuments { (snapshot, error) in
//            if error == nil, let snapshot = snapshot{
//                for document in snapshot.documents{
//                    let data = document.data()
//                    let room = Room(data: data)
//                    self.roomArray.append(room)
//                }
//                self.tableView.reloadData()
//            }
//        }
//
//        //自身が所属するルームの内容をFireStoreから取得
//        database.collection("rooms").whereField("members", arrayContains: ["userID": me.userID!, "userName": meName]).getDocuments { (snapshot, error) in
//            if error == nil, let snapshot = snapshot{
//                for document in snapshot.documents{
//                    //自身が所属するルームを配列に追加
//                    let data = document.data()
//                    let room = Room(data: data)
//                    self.roomArray.append(room)
//                }
//                self.tableView.reloadData()
//            }
//        }
//
        //roomsのinvitationから自身データを含むドキュメントを取得、invitationArrayに格納
        database.collection("rooms").whereField("invitation.\(me.userID!).userID", isEqualTo: me.userID!).getDocuments { (snapshot, error) in
            if error == nil, let snapshot = snapshot{
                for document in snapshot.documents{
                    //invitationArray はポップアップ表示の際に使われる
                    self.invitationArray.append(document.documentID)
                    let data = document.data()
                    let room = Room(data: data)
                    self.roomArray.append(room)
                }
            }
        }
        
//        //invitationから自身のデータを含むドキュメントを取得、invitationArrayに格納
//        database.collection("invitation").whereField("users", arrayContains: ["userID": me.userID!]).getDocuments { (snapshot, error) in
//            if error == nil, let snapshot = snapshot{
//                for document in snapshot.documents{
//                    //invitationArray はポップアップ表示の際に使われる
//                    self.invitationArray.append(document.documentID)
//                    //ドキュメントID == roomID のため取得し、invitationToRooms()にてroomArrayにappendを行う
//                    let roomID = document.documentID
//                    self.invitationToRooms(roomID: roomID)
//                }
//            }
//        }
//    }
            //updatedAtが新しい順にroomArrayの順番を並べ替える
            if roomArray.isEmpty != true{
                roomArray.sort(by: {$0.updatedAt.compare($1.updatedAt) == .orderedAscending})
            }
        }
//    //invitationから受け取ったroomIDでroomの情報を取得、roomArrayに追加
//    func invitationToRooms(roomID: String){
//        database.collection("rooms").document(roomID).getDocument { (snapshot, error) in
//            if error == nil, ((snapshot?.exists) != nil) ,let snapshot = snapshot{
//                let data = snapshot.data()
//                let room = Room(data: data!)
//                self.roomArray.append(room)
//            }else{
//                print("Document does not exist")
//            }
//            self.tableView.reloadData()
//        }
//    }
    
    func activeRoomFromReserved(){
        //インスタンス化
        reserveRoomArray = []
        //自身が所属・招待されている部屋の中から予約されている部屋を見つける
        for room in roomArray{
            if room.visible == false{
                reserveRoomArray.append(room)
            }
        }
        //予約時間が現在時刻を超えていたらvisibleをtrueにする
        for reserve in reserveRoomArray{
            let date = reserve.updatedAt.dateValue()
            
            if Date() >= date {
                database.collection("rooms").document(reserve.roomID).updateData([
                    "visible": true
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
                }
                //fireStoreへの情報を変更したため、roomArrayを一からやり直す
                self.roomInfo()
                //self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //予約している場合false 予約していない場合trueで処理を分ける
        if roomArray[indexPath.row].visible == true{
            //招待されているルームか既に所属しているルームかをルームIDで見分けるためにroomArray[indexPath.row].roomIDとinvitationArrayを用いる
            //invitationArray が空の時に挙動がおかしいため、if文を設ける
            if invitationArray.isEmpty != true{
                for invite in invitationArray{
                    if roomArray[indexPath.row].roomID == invite{
                        let modalViewController = storyboard?.instantiateViewController(identifier: "roomModalViewController") as! roomModalViewController
                        modalViewController.modalPresentationStyle = .custom
                        modalViewController.transitioningDelegate = self
                        //自身のIDとルームIDと自身の名前を渡す
                        modalViewController.meID = me.userID
                        modalViewController.roomID = roomArray[indexPath.row].roomID
                        modalViewController.meName = myName
                        present(modalViewController, animated: true, completion: nil)
                    }else{
                        performSegue(withIdentifier: "roomChat", sender: indexPath.row)
                    }
                }
            }else{
                performSegue(withIdentifier: "roomChat", sender: indexPath.row)
            }
            //予約しており、まだ状態がfalseの場合↓
        }else{
            if invitationArray.isEmpty != true{
                for invite in invitationArray{
                    if roomArray[indexPath.row].roomID == invite{
                        //表示するポップアップは上記と同じ(roomModalViewController)
                    }else{
                        //予約時間にならないため入室できないという旨のポップアップ
                    }
                }
            }else{
                //予約時間にならないため入室できないという旨のポップアップを
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! roomCell
        //ルームの名前を表示
        cell.roomNameLabel.text = roomArray[indexPath.row].roomName
        
        //予約した時間をreserveDayにてとってきてcellに表示
        if roomArray[indexPath.row].visible == false{
            cell.reserveLabel.text = reserveDay(updatedAt: roomArray[indexPath.row].updatedAt)
        }else{
            //ここにはすでにルームにアクセスできる部屋に対しての残り時間を表示する
        }
        
        //ルームにおける最新のメッセージを表示
        database.collection("rooms").document(roomArray[indexPath.row].roomID).collection("messages").order(by: "timeStamp", descending: true).limit(to: 1).getDocuments { (snapShot, error) in
            guard snapShot != nil else{
                print("snapShot is nil")
                return
            }
            if error == nil, let snapShot = snapShot{
                for document in snapShot.documents{
                    let data = document.data()
                    let message = GroupChat(data: data)
                    cell.messageLabel.text = message.context
                }
            }
        }
        
        //ルームのサムネイル画像を表示
        if let icon = roomArray[indexPath.row].icon{
            let storageRef = icon
            //URL型に代入
            if let photoURL = URL(string: storageRef){
                do{
                    //data→image型に代入
                    let data = try Data(contentsOf: photoURL)
                    let image = UIImage(data: data)
                    cell.roomThumbnailImageView.image = image
                }
                catch{
                    print("error")
                }
            }
        }else{
            let storageRefRoom = storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("rooms").child("roomThumbnail").child("\(roomArray[indexPath.row].roomID!).jpg")
            
            SDImageCache.shared.removeImage(forKey: "\(storageRefRoom)", withCompletion: nil)
            cell.roomThumbnailImageView.sd_setImage(with: storageRefRoom)
        }
        
        //ルームのオーナーの画像を取得・表示
        let storageRefOwner = storage.reference(forURL: "gs://depthroom-5140f.appspot.com").child("users").child("profileImage").child("\(roomArray[indexPath.row].ownerID!).jpg")
        SDImageCache.shared.removeImage(forKey: "\(storageRefOwner)", withCompletion: nil)
        cell.roomOwnerImageView.sd_setImage(with: storageRefOwner)
        
        return cell
    }
    
    func reserveDay(updatedAt: Timestamp) -> String{
        //timeStampをdateに変換
        let date = updatedAt.dateValue()
        //dateをformatを通してstringに変換
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "y年MM月dd日 HH:mm"
        
        return formatter.string(from: date)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //今回(2021/08/20)は130に設定
        return 130
    }
}

//部屋をタップした時にポップアップさせるために必要
extension myRoomsViewController: UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?{
        return customPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
