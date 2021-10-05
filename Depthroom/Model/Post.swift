//
//  Post.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/05.
//

import Foundation
import Firebase

struct Post {
    let content: String!
    let postID: String!
    let senderID: String!
    let createdAt: Timestamp!
    let updatedAt: Timestamp!

    init(data: [String: Any]) {
        content = data["content"] as? String
        postID = data["postID"] as? String
        senderID = data["senderID"] as? String
        createdAt = data["createdAt"] as? Timestamp
        updatedAt = data["updatedAt"] as? Timestamp
    }
}
