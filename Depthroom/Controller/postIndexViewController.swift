//
//  postIndexViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/10.
//

import UIKit
import Firebase

class postIndexViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    var me: AppUser!
    var database: Firestore!
    @IBOutlet weak var tableView: UITableView!
    var postArray:[Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        tableView.delegate  = self
        tableView.dataSource = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        //AppUserをFireStoreから取得
        database.collection("users").document(me.userID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.me = AppUser(data: data)
            }
        }
        
        //投稿の内容をFireStoreから取得
        database.collection("posts").getDocuments { (snapshot, error) in
            if error == nil, let snapshot = snapshot {
                self.postArray = []
                for document in snapshot.documents {
                    let data = document.data()
                    let post = Post(data: data)
                    self.postArray.append(post)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func newPost(_ sender: Any) {
        performSegue(withIdentifier: "newPost", sender: me)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newPost"{
        let nextViewController = segue.destination as! newPostViewController
            nextViewController.me = AppUser(data: ["userID": me.userID!])
        }
        
        if segue.identifier == "postShow"{
            let nextViewController = segue.destination as! postShowViewController
            nextViewController.post = Post(data: ["postID": postArray[sender as! Int].postID!])
            nextViewController.senderID = self.postArray[sender as! Int].senderID
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //投稿詳細への遷移
        performSegue(withIdentifier: "postShow", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = postArray[indexPath.row].content
        
        //senderIDよりAppUser情報をFireStoreから取得
        database.collection("users").document(postArray[indexPath.row].senderID).getDocument { (snapshot, error) in
            
               if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                   let appUser = AppUser(data: data)
                   cell.detailTextLabel?.text = appUser.userName
               }
           }
        return cell
    }
    
    
}
