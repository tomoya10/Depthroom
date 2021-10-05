//
//  Follow.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/07/16.
//

import Foundation
import Firebase

struct Follow {
    let followID: String!
    let followingID: String!
    let followedID: String!

    init(data: [String: Any]) {
        followID = data["followID"] as? String
        followingID = data["followingID"] as? String
        followedID = data["followedID"] as? String
    }
}
