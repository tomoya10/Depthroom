//
//  AppUser.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import Foundation
import Firebase

struct AppUser {
    
    let userID: String!
    let description: String!
    let userName: String!
    let follow: [String:Any]!
    let follower: [String:Any]!
    let icon: String!
    
    init(data: [String:Any]) {
        
        userID = data["userID"] as? String
        description = data["description"] as? String
        userName = data["userName"] as? String
        follow = data["follow"] as? [String:Any]
        follower = data["follower"] as? [String:Any]
        icon = data["icon"] as? String
    }
}
