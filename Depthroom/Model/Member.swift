//
//  Member.swift
//  Depthroom
//
//  Created by Tomoya Asai on 2021/09/17.
//

import Foundation
import Firebase

struct Member {
    let users: [String]!
    //let userID: String!


    init(data: [String: Any]) {
        users = data["users"] as? [String]
        //userID = data["userID"] as? String

    }
}
