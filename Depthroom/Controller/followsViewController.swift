//
//  followsViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/16.
//

import UIKit
import Firebase

class followsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var user: AppUser!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    //ユーザがフォローしている人の配列
    var followArray:[AppUser] = []
    //ユーザをフォローしてくれている人の配列
    var followerAraay:[AppUser] = []
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        tableView.delegate = self
        tableView.dataSource = self
        followArray = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
            //ユーザネーム・フォロー周りの情報を表示
            database.collection("users").document(user.userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                    self.user = AppUser(data: data)
                    self.userNameLabel.text = self.user.userName
                    
                    //フォロー情報を配列に格納
                    if let follow = data["follow"] as? [String:Any]{
                        for follow in follow.values{
                            let userInfo = AppUser(data: follow as! [String:Any])
                            self.followArray.append(userInfo)
                        }
                    }
                    //フォロワー情報を配列に格納
                    if let follower = data["follower"] as? [String:Any]{
                        for follower in follower.values{
                            let userInfo = AppUser(data: follower as! [String:Any])
                            self.followerAraay.append(userInfo)
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
                nextViewController.user = AppUser(data: ["userID": followArray[sender as! Int].userID!])
            case 1:
                nextViewController.user = AppUser(data: ["userID": followerAraay[sender as! Int].userID!])
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
        performSegue(withIdentifier: "userMyPage", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            return followArray.count
        case 1:
            return followerAraay.count
        default:
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let segmentIndex = selectSegmentedControl.selectedSegmentIndex
        switch segmentIndex {
        case 0:
            database.collection("users").document(followArray[indexPath.row].userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    let appUser = AppUser(data: data)
                    cell.textLabel?.text = appUser.userName
                }
            }
        case 1:
            database.collection("users").document(followerAraay[indexPath.row].userID).getDocument { (snapshot, error) in
                if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                    let appUser = AppUser(data: data)
                    cell.textLabel?.text = appUser.userName
                }
            }
            
        default:
            break
        }
        return cell
    }

}
