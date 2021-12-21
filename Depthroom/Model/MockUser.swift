//
//  MockUser.swift
//  Depthroom
//
//  Created by Tomoya Asai on 2021/11/04.
//

import Foundation
import MessageKit

struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
}
