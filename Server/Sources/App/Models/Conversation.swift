//
//  Conversation.swift
//  App
//
//  Created by Be More on 20/11/2020.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Conversation: Content {
    var id: UUID?
    var fromUId: User.ID
    var toUId: User.ID
    var messageId: Message.ID
    
    init (from: User.ID, to: User.ID, message: Message.ID) {
        self.fromUId = from
        self.toUId = to
        self.messageId = message
    }
}

extension Conversation: MySQLUUIDModel { }

extension Conversation: Migration {
    
    typealias Database = MySQLDatabase
    
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.fromUId, to: \User.id)
            builder.reference(from: \.messageId, to: \Message.id)
        }
    }
    
}

extension Conversation: Parameter { }

extension Conversation {
    
    var user: Parent<Conversation, User> {
        return parent(\.fromUId)
    }
    
    var message: Parent<Conversation, Message> {
        return parent(\.messageId)
    }
    
}
