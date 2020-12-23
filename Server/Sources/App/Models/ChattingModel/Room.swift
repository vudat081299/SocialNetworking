//
//  Room.swift
//  App
//
//  Created by Vũ Quý Đạt  on 23/12/2020.
//

import Vapor
import FluentMySQL

final class Room: Codable {
    var id: Int?
    var sumUserID: String
    var useridText1: String
    var useridText2: String
    var userID1: User.ID
    var userID2: User.ID
    
    init(test: String, sumUserID: String, useridText1: String, useridText2: String, userID1: User.ID, userID2: User.ID) {
        self.sumUserID = sumUserID
        self.useridText1 = useridText1
        self.useridText2 = useridText2
        self.userID1 = userID1
        self.userID2 = userID2
    }
}

/// Uncomment to use instead of MySQLModel extension below, but which is using is better more than code in comment.
//extension Acronym: Model {
//    typealias  Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id
//}

//extension Acronym: MySQLModel {}
extension Room: MySQLModel {
    typealias Database = MySQLDatabase
}
//extension Acronym: Migration {}
extension Room: Content {}
extension Room: Parameter {}

//MARK: Help to get users of acronyms.
extension Room {
    var user1: Parent<Room, User> {
        return parent(\.userID1)
    }
    var user2: Parent<Room, User> {
        return parent(\.userID2)
    }
}

extension Room {
    var messages: Children<Room, Message> {
        return children(\.roomID)
    }
}

//MARK: Foreign key constraints.
///     Using foreign key constraints has a number of benefits:
///     It ensures you can’t create acronyms with users that don’t exist.
///     You can’t delete users until you’ve deleted all their acronyms.
///     You can’t delete the user table until you’ve deleted the acronym table.
extension Room: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID1, to: \User.id)
            builder.reference(from: \.userID2, to: \User.id)
            builder.unique(on: \.sumUserID)
            
        }
    }
}



