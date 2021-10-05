//
//  Room.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/08.
//

import Foundation
import Firebase

struct Room {
    let roomID: String!
    let roomName: String!
    let description: String!
    let ownerID: String!
    let createdAt: Timestamp!
    let updatedAt: Timestamp!
    let visible: Bool!
    let icon: String!

    init(data: [String: Any]) {
        roomID = data["roomID"] as? String
        roomName = data["roomName"] as? String
        description = data["description"] as? String
        ownerID = data["ownerID"] as? String
        createdAt = data["createdAt"] as? Timestamp
        updatedAt = data["updatedAt"] as? Timestamp
        visible = data["visible"] as? Bool
        icon = data["icon"] as? String
    }
}
