import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseStorageUI

class directMessageViewController: MessagesViewController {
    
    var user: AppUser!
    var me: AppUser!
    var meName = "initial"
    
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    
    var messageList: [MockMessage] = [] {
        didSet {
            // messagesCollectionViewをリロード
            self.messagesCollectionView.reloadData()
            // 一番下までスクロールする
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()
        
        //meNameはcurrentSender()メソッドで使用される
        database.collection("users").document(Auth.auth().currentUser!.uid).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.me = AppUser(data: data)
                //初期値が入ったmeNameに代入することでnilを回避
                self.meName = self.me.userName
            }
        }
        //Dispatch処理にfireStoreDocumentChangeメソッド入れるのは無意味(snapShotがあるため被っている)
        //DispatchQueue.main.async {
        //    self.fireStoreDocumentChange()
        //}
        fireStoreDocumentChange()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInput()
        setupButton()
        // 背景の色を指定
        messagesCollectionView.backgroundColor = .white
        
        // メッセージ入力時に一番下までスクロール
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func fireStoreDocumentChange(){
        
        //自身のidと相手のidを組み合わせてドキュメントidを作成、そこにデータを入れる
        let userIds = [user.userID, auth.currentUser!.uid].sorted()
        let id = userIds[0] + userIds[1]
        
        //チャット内容をFireStoreから取得・ドキュメントに変更が生じた際、messageListにドキュメントを追加する
        database.collection("dm").document(id).collection("messages").order(by: "timeStamp", descending: false).addSnapshotListener { (snapShot, error) in
            guard snapShot != nil else {
                print("snapShot is nil")
                return
            }
            snapShot!.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("New city: \(diff.document.data())")
                    let snapshotValue = diff.document.data()
                    let text = snapshotValue["context"] as! String
                    let id = snapshotValue["senderID"] as! String
                    let name = snapshotValue["senderName"] as! String
                    //fireStoreのFieldValueからdateに変換
                    //let createTime = snapshotValue["timeStamp"] as! Timestamp
                    //let date = createTime.dateValue()
                    let createTime = snapshotValue["timeStamp"] as! Timestamp
                    let date = createTime.dateValue()
                    print("\(date)です")
                    self.messageList.append(self.createMessage(text: text, id: id, name: name, date: date))
                }
                if (diff.type == .modified) {
                    print("Modified city: \(diff.document.data())")
                }
                if (diff.type == .removed) {
                    print("Removed city: \(diff.document.data())")
                }
            }
        }
    }
    
    private func setupInput(){
        // プレースホルダーの指定
        messageInputBar.inputTextView.placeholder = "入力"
        // 入力欄のカーソルの色を指定
        messageInputBar.inputTextView.tintColor = .blue
        // 入力欄の色を指定
        messageInputBar.inputTextView.backgroundColor = .white
    }
    
    private func setupButton(){
        // ボタンの変更
        messageInputBar.sendButton.title = "送信"
        // 送信ボタンの色を指定
        messageInputBar.sendButton.tintColor = .lightGray
    }
    
    func createMessage(text: String, id: String, name: String, date: Date) -> MockMessage {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white]
        )
        return MockMessage(attributedText: attributedText, sender:otherSender(senderID: id, displayName: name), messageId: UUID().uuidString, date: date)
    }
}

// MARK: - MessagesDataSource
extension directMessageViewController: MessagesDataSource {
    
    //自分を認識
    func currentSender() -> SenderType {
        //idは既に持っているためmeNameのみ
        return sendUser(senderId: Auth.auth().currentUser!.uid, displayName: meName)
    }
    
    //相手を認識
//    func otherSender() -> SenderType {
//        Firestore.firestore().collection("users").document(user.userID).getDocument { (snapshot, error) in
//            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
//                self.user = AppUser(data: data)
//
//            }
//        }
//        return sendUser(senderId: user.userID, displayName: user.userName)
//    }
    //相手を認識改自分も認識している説
    func otherSender(senderID: String, displayName: String) -> SenderType {
        return sendUser(senderId: senderID, displayName: displayName)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    // メッセージの上に文字を表示
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
            )
        }
        return nil
    }
    
    // メッセージの上に文字を表示（名前）
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下に文字を表示（日付）
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// MARK: - MessagesDisplayDelegate
extension directMessageViewController: MessagesDisplayDelegate {
    
    // メッセージの色を変更
    func textColor(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        isFromCurrentSender(message: message) ? .white : .darkGray
    }
    
    // メッセージの背景色を変更している
    func backgroundColor(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        isFromCurrentSender(message: message) ? .darkGray : .darkGray
    }
    
    // メッセージの枠にしっぽを付ける
    func messageStyle(
        for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコンをセット
    func configureAvatarView(
        _ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView
    ) {
        
        //冗長ではあるが、クロージャの関係上メソッド化しづらい
        //今後改良の余地あり
        if message.sender.senderId == auth.currentUser?.uid{
            let storageRef = userProfileImageStorageRef(userID: auth.currentUser!.uid)
            SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
            //urlを取ってくる
            storageRef.downloadURL(completion: {(url, error) in
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
                        avatarView.set( avatar: Avatar(image: image) )
                    }
                    catch{
                        print("error")
                        return
                    }
                    
                }
            })
        }
        else if message.sender.senderId == user.userID{
            let storageRef = userProfileImageStorageRef(userID: user.userID)
            SDImageCache.shared.removeImage(forKey: "\(storageRef)", withCompletion: nil)
            //urlを取ってくる
            storageRef.downloadURL(completion: {(url, error) in
                if error != nil{
                    print("error: \(error!.localizedDescription)")
                    return
                }
                //URL型に代入
                if let photoURL = URL(string: url!.absoluteString){
                    //data型→image型に代入して、returnを返す
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        avatarView.set( avatar: Avatar(image: image) )
                    }
                    catch{
                        print("error")
                        return
                    }
                    
                }
            })
        }
    }
    
    //ここでfireStoreからパスを得る
    func userProfileImageStorageRef(userID: String) -> StorageReference{
        let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("users").child("profileImage").child("\(userID).jpg")
        return storageRef
    }
}


// 各ラベルの高さを設定（デフォルト0なので必須）
// MARK: - MessagesLayoutDelegate
extension directMessageViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        indexPath.section % 3 == 0 ? 10 : 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        16
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        16
    }
}

// MARK: - MessageCellDelegate
extension directMessageViewController: MessageCellDelegate {
    
    //MARK: - Cellのバックグラウンドをタップした時の処理
    func didTapBackground(in cell: MessageCollectionViewCell) {
        print("バックグラウンドタップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージをタップした時の処理
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("メッセージタップ")
        closeKeyboard()
    }
    
    //MARK: - アバターをタップした時の処理
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("アバタータップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージ上部をタップした時の処理
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ上部タップ")
        closeKeyboard()
    }
    
    //MARK: - メッセージ下部をタップした時の処理
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("メッセージ下部タップ")
        closeKeyboard()
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension directMessageViewController: InputBarAccessoryViewDelegate {
    // 送信ボタンをタップした時の挙動
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //let attributedText = NSAttributedString(
            //string: text, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
        //let message = MockMessage(attributedText: attributedText, sender: currentSender(), messageId: UUID().uuidString, date: Date())
        //self.messageList.append(message)
        
        self.messageInputBar.inputTextView.text = String()
        self.messageInputBar.invalidatePlugins()
        self.messagesCollectionView.scrollToLastItem()
        
        //自身のidと相手のidを組み合わせてドキュメントidを作成、そこにデータを入れる
        let userIds = [user.userID, auth.currentUser!.uid].sorted()
        let id = userIds[0] + userIds[1]
        
        let saveMessage = database.collection("dm").document(id).collection("messages").document()
        
        saveMessage.setData([
            "senderID": currentSender().senderId,
            "senderName": currentSender().displayName,
            "context": text,
            "messageID": saveMessage.documentID,
            //"timeStamp": FieldValue.serverTimestamp()
            "timeStamp": NSDate()
        ])
    }
    
}

extension directMessageViewController {
    func closeKeyboard(){
        self.messageInputBar.inputTextView.resignFirstResponder()
        self.messagesCollectionView.scrollToLastItem()
    }
}
