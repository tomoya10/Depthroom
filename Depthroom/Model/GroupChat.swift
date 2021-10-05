//
//  GroupChat.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/16.
//

import Foundation
import Firebase

struct GroupChat {
    let context: String!
    let messageID: String!
    let senderID: String!
    let senderName: String!
    let timeStamp: Timestamp!

    init(data: [String: Any]) {
        context = data["context"] as? String
        messageID = data["messageID"] as? String
        senderID = data["senderID"] as? String
        senderName = data["senderName"] as? String
        timeStamp = data["timeStamp"] as? Timestamp
    }
}
