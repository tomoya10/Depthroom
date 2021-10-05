import MessageKit
import UIKit
import InputBarAccessoryView
import Firebase

struct sendUser: SenderType {
    var senderId: String
    let displayName: String
}

struct MockMessage: MessageType {

    var messageId: String
    var sender: SenderType
    var sentDate: Date
    //MessageKindはテキストや画像や動画絵文字の区別
    var kind: MessageKind

    private init(kind: MessageKind, sender: SenderType, messageId: String, date: Date) {
        self.kind = kind
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }

    //kind によって、テキストか画像か動画かを見分ける
    init(text: String, sender: SenderType, messageId: String, date: Date) {
        self.init(kind: .text(text), sender: sender, messageId: messageId, date: date)
    }

    init(attributedText: NSAttributedString, sender: SenderType, messageId: String, date: Date) {
        self.init(kind: .attributedText(attributedText), sender: sender, messageId: messageId, date: date)
    }
}
