//
//  Notification.swift
//  App
//
//  Created by Be More on 23/11/2020.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Notification: Content {
    var timestamp: Date
    var id: Int?
    var type: Int
    var userId: User.ID
    var fromUserId: User.ID
    var postId: Post.ID
    var seen = false
    
    init(timestamp: Date, type: Int, userId: User.ID, fromUserId: User.ID, postId: Post.ID) {
        self.timestamp = timestamp
        self.type = type
        self.userId = userId
        self.fromUserId = fromUserId
        self.postId = postId
    }
}

extension Notification {
    var user: Parent<Notification, User> {
        return parent(\.userId)
    }
    
    var post: Parent<Notification, Post> {
        return parent(\.postId)
    }
    
}

extension Notification: MySQLModel {
    typealias Database = MySQLDatabase
}

extension Notification: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userId, to: \User.id)
            builder.reference(from: \.postId, to: \Post.id)
        }
    }
}

extension Notification: Parameter { }
