//
//  Location.swift
//  App
//
//  Created by Vu Quy Dat on 15/12/2020.
//

struct MessageContent: Content {
}
import Vapor
import FluentMySQL

final class Message: Codable {
    var id: Int?
    let time: String
    let content: String
    let roomID: Room.ID
    var from: String
    var to: String
    
    init(time: String, content: String, roomID: Room.ID, from: String, to: String) {
        self.time = time
        self.content = content
        self.roomID = roomID
        self.from = from
        self.to = to
    }
}

/// Uncomment to use instead of MySQLModel extension below, but which is using is better more than code in comment.
//extension Acronym: Model {
//    typealias  Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id
//}

// extension Acronym: MySQLModel {}
extension Message: MySQLModel {
    typealias Database = MySQLDatabase
}
// extension Acronym: Migration {}
extension Message: Content {}
extension Message: Parameter {}

// MARK: Help to get users of acronyms.
extension Message {
    var room: Parent<Message, Room> {
        return parent(\.roomID)
    }
    
    //    // 1
    //    var categories: Siblings<Acronym, Category, AcronymCategoryPivot> {
    //        // 2
    //        return siblings()
    //    }/*
    //     1. Add a computed property to Acronym to get an acronym’s categories. This returns Fluent’s generic Sibling type. It returns the siblings of an Acronym that are of type Category and held using the AcronymCategoryPivot.
    //     2. Use Fluent’s siblings() function to retrieve all the categories. Fluent handles everything else.
    //     */
}

// MARK: Foreign key constraints.
///     Using foreign key constraints has a number of benefits:
///     It ensures you can’t create acronyms with users that don’t exist.
///     You can’t delete users until you’ve deleted all their acronyms.
///     You can’t delete the user table until you’ve deleted the acronym table.
extension Message: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.roomID, to: \Room.id)
        }
    }
}



