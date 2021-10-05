//
//  newPostViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/10.
//

import UIKit
import Firebase

class newPostViewController: UIViewController {
    
    var me: AppUser!
    @IBOutlet weak var postContent: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func createPost(_ sender: Any) {
        
        let content = postContent.text!
        if content != ""{
            let saveContent = Firestore.firestore().collection("posts").document()
            
            saveContent.setData([
                "content": content,
                "postID": saveContent.documentID,
                "senderID": me.userID!,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]){ error in
                if error == nil{
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    func setupTextView() {
        //キーボードの上に置くツールバーの生成
        let toolBar = UIToolbar()
        // 今回は、右端にDoneボタンを置きたいので、左に空白を入れる
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        // Doneボタン
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        // ツールバーにボタンを配置
        toolBar.items = [flexibleSpaceBarButton, doneButton]
        toolBar.sizeToFit()
        // テキストビューにツールバーをセット
        postContent.inputAccessoryView = toolBar
    }
    
    // キーボードを閉じる処理。
    @objc func dismissKeyboard() {
        postContent.resignFirstResponder()
    }
}
