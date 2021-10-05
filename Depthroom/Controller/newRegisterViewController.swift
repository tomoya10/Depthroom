//
//  newRegisterViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import UIKit
import Firebase

class newRegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var auth: Auth!
    var database: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        do{
//        try Auth.auth().signOut()
//        }catch{}
        auth = Auth.auth()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if auth.currentUser != nil{
            performSegue(withIdentifier: "addition", sender: auth.currentUser!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        if segue.identifier == "addition"{
          let nextViewController = segue.destination as! additionalRegisterViewController
            let user = sender as! User
            nextViewController.me = AppUser(data: ["userID" : user.uid])
        }
        if segue.identifier == "rooms"{
            let nextViewController = segue.destination as! myRoomsViewController
            let user = sender as! User
            nextViewController.me = AppUser(data: ["userID" : user.uid])
        }
      }
    
    @IBAction func registerAccount(_ sender: Any) {
        
        if emailTextField.text?.isEmpty != true && passwordTextField.text?.isEmpty != true{
            
            auth.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { result, error in
                
                if error == nil, let result = result{
                    
                    self.performSegue(withIdentifier: "addition", sender: result.user)
                }
                self.showErrorIfNeeded(error)
            }
        }
    }
    
    @IBAction func buttonToLogin(_ sender: Any) {
        let loginViewController = storyboard?.instantiateViewController(identifier: "login") as! loginViewController
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    //エラーに関する記述
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error) // エラーメッセージを取得
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func errorMessage(of error: Error) -> String {
        var message = "エラーが発生しました"
        guard let errcd = AuthErrorCode(rawValue: (error as NSError).code) else {
            return message
        }
        
        switch errcd {
            case .networkError: message = "ネットワークに接続できません"
            case .userNotFound: message = "ユーザが見つかりません"
            case .invalidEmail: message = "不正なメールアドレスです"
            case .emailAlreadyInUse: message = "このメールアドレスは既に使われています"
            case .wrongPassword: message = "入力した認証情報でサインインできません"
            case .userDisabled: message = "このアカウントは無効です"
            case .weakPassword: message = "パスワードが脆弱すぎます"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
}

extension newRegisterViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
