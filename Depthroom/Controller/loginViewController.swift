//
//  loginViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/02.
//

import UIKit
import Firebase

class loginViewController: UIViewController {

    var me: AppUser!
    var auth: Auth!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func loginButton(_ sender: Any) {
        
        if emailTextField.text?.isEmpty != true && passwordTextField.text?.isEmpty != true{
            
            auth.signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { [weak self] result, error in
                    guard let self = self else { return }
                if let user = result?.user {
                    self.performSegue(withIdentifier: "rooms", sender: user)
                }
                self.showErrorIfNeeded(error)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "rooms"{
          let nextViewController = segue.destination as! myRoomsViewController
          let user = sender as! User
            nextViewController.me = AppUser(data: ["userID": user.uid])
        }
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
        case .wrongPassword: message = "入力した認証情報でサインインできません"
        case .userDisabled: message = "このアカウントは無効です"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
        
}

extension loginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
    
