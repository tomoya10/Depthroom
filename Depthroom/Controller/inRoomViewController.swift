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
    
    var membersArray:[AppUser] = [] {
        didSet{
            //membersArray配列に変化があった際に呼ばれる
            tableView.reloadData()
        }
    }
    
    var invitationArray:[AppUser] = [] {
        didSet{
            //membersArray配列に変化があった際に呼ばれる
            tableView.reloadData()
        }
    }
    
    
    //ルームメンバーの配列
    var members:[String] = []
    //招待されている人の配列
    var invitation:[String] = []
    
    //ルームメンバーの配列
    var membersID:[AppUser] = []
    //招待されている人の配列
    var invitationID:[AppUser] = []
    
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
                }
            }

        membersArray = []
        invitationArray = []
        //ルームのメンバーのIDをFireStoreから取得、配列に格納
        database.collection("rooms").document(room.roomID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                if let members = data["members"] as? [String:Any]{
                    for members in members.values{
                        let memberInfo = AppUser(data: members as! [String:Any])
                        self.membersArray.append(memberInfo)
                    }
                }
                
                if let invitation = data["invitation"] as? [String:Any]{
                    for invitation in invitation.values{
                        let invitationInfo = AppUser(data: invitation as! [String:Any])
                        self.invitationArray.append(invitationInfo)
                    }
                }
                self.tableView.reloadData()
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
                nextViewController.user = AppUser(data: ["userID": membersArray[sender as! Int].userID!])
            case 1:
                nextViewController.user = AppUser(data: ["userID": invitationArray[sender as! Int].userID!])
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
            return membersArray.count
        case 1:
            return invitationArray.count
        default:
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            database.collection("users").document(membersArray[indexPath.row].userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    let membersUser = AppUser(data: data)
                    //cell.textLabel?.text = membersArray[indexPath.row].userName
                    //print("members:", appUser.userName)
                    cell.textLabel?.text = membersUser.userName
                }
            }
        case 1:
            database.collection("users").document(invitationArray[indexPath.row].userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    let invitationUser = AppUser(data: data)
                    //print("invitation:", appUser.userName)
                    cell.textLabel?.text = invitationUser.userName
                }
            }
            
        default:
            break
        }
        return cell
    }
    
}
