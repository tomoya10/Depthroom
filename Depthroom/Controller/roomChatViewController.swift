//
//  roomChatViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/13.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseStorageUI
import Photos
import FirebaseStorage


class roomChatViewController: MessagesViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var room: Room!
    var database: Firestore!
    var storage: Storage!
    var auth: Auth!
    var meName = "initial"
    var me: AppUser!
    
    var messageList: [MockMessage] = []{
        didSet{
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
    
//    private var isSendingPhoto = false {
//      didSet {
//        messageInputBar.leftStackViewItems.forEach { item in
//          guard let item = item as? InputBarButtonItem else {
//            return
//          }
//          item.isEnabled = !self.isSendingPhoto
//        }
//      }
//    }
//    private let storage1 = Storage.storage().reference(forURL: "gs://depthroom-5140f.appspot.com")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        database = Firestore.firestore()
        storage = Storage.storage()
        auth = Auth.auth()

        database.collection("users").document(auth.currentUser!.uid).getDocument { (snapshot, error) in
            if error == nil, let snapshot = snapshot, let data = snapshot.data(){
                self.me = AppUser(data: data)
                //初期値が入ったmeNameに代入することでnilを回避
                self.meName = self.me.userName
            }
        }
        let rightBarButton = UIBarButtonItem(title: "チャットルーム参加者", style: .plain, target: self, action: #selector(tappedAddRightBarButton))
        navigationItem.rightBarButtonItem = rightBarButton
        
        
        
        
        fireStoreDocumentChange()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInput()
        setupButton()
        addCameraBarButton()

        
        // 背景の色を指定
        messagesCollectionView.backgroundColor = .white
        
        // メッセージ入力時に一番下までスクロール
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
    }
    
    // MARK: - Actions
    @objc private func cameraButtonPressed() {
      let picker = UIImagePickerController()
      picker.delegate = self

      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        picker.sourceType = .camera
      } else {
        picker.sourceType = .photoLibrary
      }
        //upload()
      present(picker, animated: true)
        
    }
    
    //チャットルーム参加者一覧
    @objc private func tappedAddRightBarButton() {
        let storyboard: UIStoryboard = self.storyboard!
        let inRoomViewController = storyboard.instantiateViewController(identifier: "inRoomViewController") as! inRoomViewController
        inRoomViewController.user = me
        inRoomViewController.room = room
        
        navigationController?.pushViewController(inRoomViewController, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //今回はナビゲーションバーを表示
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func fireStoreDocumentChange(){
        //チャット内容をFireStoreから取得・ドキュメントに変更が生じた際、messageListにドキュメントを追加するroom.roomID
        database.collection("rooms").document(room.roomID).collection("messages").order(by: "timeStamp", descending: false).addSnapshotListener { (snapShot, error) in
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
    
//    fileprivate func upload() {
//           let date = NSDate()
//           let currentTimeStampInSecond = UInt64(floor(date.timeIntervalSince1970 * 1000))
//        let storageRef = storage.reference(forURL: "gs://depthroom-5140f.appspot.com/").child("chat").child("\(currentTimeStampInSecond).jpg")
//          // let storageRef = Storage.storage().reference().child("images").child("\(currentTimeStampInSecond).jpg")
//           let metaData = StorageMetadata()
//           metaData.contentType = "image/jpg"
//           if let uploadData = self.imageView.image?.jpegData(compressionQuality: 0.9) {
//               storageRef.putData(uploadData, metadata: metaData) { (metadata , error) in
//                   if error != nil {
//                       print("error: \(error?.localizedDescription)")
//                   }
//                   storageRef.downloadURL(completion: { (url, error) in
//                       if error != nil {
//                           print("error: \(error?.localizedDescription)")
//                       }
//                       print("url: \(url?.absoluteString)")
//                   })
//               }
//           }
//       }
    
  
    // MARK: - setupInputBarButton
    private func removeMessageAvatars() {
      guard let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else {
        return
      }
      layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
      layout.textMessageSizeCalculator.incomingAvatarSize = .zero
      layout.setMessageIncomingAvatarSize(.zero)
      layout.setMessageOutgoingAvatarSize(.zero)
      let incomingLabelAlignment = LabelAlignment(
        textAlignment: .left,
        textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
      layout.setMessageIncomingMessageTopLabelAlignment(incomingLabelAlignment)
      let outgoingLabelAlignment = LabelAlignment(
        textAlignment: .right,
        textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
      layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }
    
    private func addCameraBarButton() {
      // 1
      let cameraItem = InputBarButtonItem(type: .system)
      cameraItem.tintColor = .lightGray
      cameraItem.image = UIImage(named: "home")

      // 2
      cameraItem.addTarget(
        self,
        action: #selector(cameraButtonPressed),
        for: .primaryActionTriggered)
      cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
      messageInputBar.leftStackView.alignment = .center
      messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

      // 3
      messageInputBar
        .setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    private func setupInput(){
        // プレースホルダーの指定
        messageInputBar.inputTextView.placeholder = "入力"
        // 入力欄のカーソルの色を指定
        messageInputBar.inputTextView.tintColor = .red
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
extension roomChatViewController: MessagesDataSource {
    
    //自分を認識
    func currentSender() -> SenderType {
        //idは既に持っているためmeNameのみ
        return sendUser(senderId: Auth.auth().currentUser!.uid, displayName: meName)
    }

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
extension roomChatViewController: MessagesDisplayDelegate {
    
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
        isFromCurrentSender(message: message) ? .darkGray : .cyan
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
        else{
            let storageRef = userProfileImageStorageRef(userID: message.sender.senderId)
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
extension roomChatViewController: MessagesLayoutDelegate {
    
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
extension roomChatViewController: MessageCellDelegate {
    
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
extension roomChatViewController: InputBarAccessoryViewDelegate {
    // 送信ボタンをタップした時の挙動
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //let attributedText = NSAttributedString(
            //string: text, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
        //let message = MockMessage(attributedText: attributedText, sender: currentSender(), messageId: UUID().uuidString, date: Date())
        //self.messageList.append(message)
        
        self.messageInputBar.inputTextView.text = String()
        self.messageInputBar.invalidatePlugins()
        self.messagesCollectionView.scrollToLastItem()
        
        //送信したデータをFireStoreに保存
        let saveMessage = database.collection("rooms").document(room.roomID).collection("messages").document()
        
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

extension roomChatViewController {
    func closeKeyboard(){
        self.messageInputBar.inputTextView.resignFirstResponder()
        self.messagesCollectionView.scrollToLastItem()
    }
}

//extension roomChatViewController: CameraInputBarAccessoryViewDelegate {
//
//    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [AttachmentManager.Attachment]) {
//
//
//        for item in attachments {
//            if  case .image(let image) = item {
//
//                self.sendImageMessage(photo: image)
//            }
//        }
//        inputBar.invalidatePlugins()
//    }
//
//
//    func sendImageMessage( photo  : UIImage)  {
//
//        let photoMessage = MockMessage(image: photo, user: self.currentSender() as! MockUser, messageId: UUID().uuidString, date: Date())
//        self.insertMessage(photoMessage)
//    }
//
//}
