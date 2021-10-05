//
//  followsViewController.swift
//  Depthroom
//
//  Created by Asai Tomoya on 2021/09/16.
//

import UIKit
import Firebase

class inRoomViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    var room: Room!
    var user: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
//    var invitation: Invitation!
//    var member: Member!
    
    //ルームメンバーの配列
    var members:[[String:Any]] = []
    //招待されている人の配列
    var invitation:[String] = []

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var selectSegmentedControl: UISegmentedControl!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        //ユーザネームを表示
        database.collection("rooms").document(
            room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.room = Room(data: data)
                self.roomNameLabel.text = self.room.roomName
                print(self.room.roomName!)//!つけた
            }
        }
        
        //ルームのメンバーのIDをFireStoreから取得、配列に格納
//        database.collection("members").document(room.roomID).getDocument { (snapshot, error) in
//            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
//                let mapData = data["users"] //as! [String:Any]
//                //self.members = []
//               // self.members.append(mapData!)
//                print(Array(data.keys))
//                print("data.value:",Array(data.values))
//                print("member.mapData",mapData ?? 0)
//            }
//        }
        
        //招待されている人のIDをFireStoreから取得、配列に格納
        
        database.collection("invitation").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot , let data = snapshot.data(){
//                  let mapData = data["users"]
                let dic_objc = NSMutableDictionary(dictionary: data)
                let mapData = dic_objc as NSDictionary as! [String: Any]
                let valuedata = mapData["users"] as! [AnyObject]
                //let userid = valuedata[0][0]["userID"]
                //let idvalue = mapData.object["userID"]
//                if(mapData as AnyObject).isEmpty == true{
//                    print("何もない")
//                }else{
//                    print("ある")
//                }
//                for value in valuedata {
//                    print(value)
//                }
                print(Array(data.keys))
                print("valuedata: ", valuedata[0])
                //object.getForKey("userID") as! String
                self.invitation = []
                //self.invitation.append(valuedata["userID"])
//                print("valuedata:",valuedata[0])
//                print("invitation:",self.invitation[0])
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //フォロー・フォロワーごとに配列を切り替えて遷移の値渡しを行なっている
        if segue.identifier == "userMyPage"{
            let nextViewController = segue.destination as! myPageViewController
            let segmentIndex = selectSegmentedControl.selectedSegmentIndex
            switch segmentIndex {
            case 0:
                nextViewController.user = AppUser(data: ["userID": members[sender as! Int]])
            case 1:
                nextViewController.user = AppUser(data: ["userID": invitation[sender as! Int]])
            default:
                break
            }
        }
    }
    
    @IBAction func tappedSegmentedControl(_ sender: Any) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ユーザのマイページに遷移
        //performSegue(withIdentifier: "userMyPage", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            return members.count
        case 1:
            return invitation.count
        default:
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
//        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
//        switch segmentIndex {
//        case 0:
//            database.collection("users").document(members[indexPath.row]).getDocument { (snapshot, error) in
//                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
//                    let appUser = AppUser(data: data)
//                    cell.textLabel?.text = appUser.userName
//                }
//            }
//        case 1:
//            database.collection("users").document(invitation[indexPath.row]).getDocument { (snapshot, error) in
//                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
//                    let appUser = AppUser(data: data)
//                    cell.textLabel?.text = appUser.userName
//                }
//            }
//
//        default:
//            break
//        }
        return cell
    }

}
