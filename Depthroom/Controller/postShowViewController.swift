//
//  postShowViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/11.
//

import UIKit
import Firebase
import FirebaseStorageUI

class postShowViewController: UIViewController {

    var post: Post!
    //今回は他人も含むためmeではなく、userで
    var user: AppUser!
    var senderID: String!
    var database: Firestore!
    var storage: Storage!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var postContent: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        database = Firestore.firestore()
        storage = Storage.storage()
        profileImage.layer.cornerRadius = 45
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //ナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        //PostをFireStoreから取得、投稿内容を表示
        database.collection("posts").document(post.postID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.post = Post(data: data)
                //投稿内容を表示
                self.postContent.text = self.post.content
            }
        }
        
        //ユーザネームを表示
        database.collection("users").document(senderID).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data() {
                self.user = AppUser(data: data)
                self.userNameLabel.text = self.user.userName
            }
        }
        
        let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("users").child("profileImage").child("\(senderID!).jpg")
        
        //キャッシュを消して画像を表示
        SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
        profileImage.sd_setImage(with: storageRef)
    }
    
    @IBAction func tapToOtherPage(_ sender: Any) {
        performSegue(withIdentifier: "otherPage", sender: user)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //他人のマイページへ遷移
        if segue.identifier == "otherPage"{
            let nextViewController = segue.destination as! myPageViewController
            nextViewController.user = AppUser(data: ["userID": senderID!])
        }
    }
    
}
