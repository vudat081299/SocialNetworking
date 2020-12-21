//
////  Message.swift
////  App
////
////  Created by Be More on 20/11/2020.
////
//
//import Foundation
//import Vapor
//import FluentMySQL
//import Authentication
//
//final class Message: Content {
//    var id: UUID?
//    var message: String
//    var created: Date
//    var fromUId: User.ID
//    var toUId: User.ID
//
//    init(_ message: String, _ created: Date, fromUId: User.ID, _ toUId: User.ID) {
//        self.message = message
//        self.created = created
//        self.fromUId = fromUId
//        self.toUId = toUId
//    }
//}
//
//extension Message {
//    var conversation: Children<Message, Conversation> {
//        return children(\.messageId)
//    }
//}
//
//extension Message: MySQLUUIDModel {
//
//}
//
//extension Message: Migration {
//    typealias Database = MySQLDatabase
//}
//
//extension Message: Parameter { }
