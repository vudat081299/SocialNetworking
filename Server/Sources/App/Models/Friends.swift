import Vapor
import FluentMySQL

final class Friend: Codable {
    var id: Int?
    var friendID: String
    var dateSend: String
    var dateAccept: String
    var isBlocked: String
    var isAccept: String // may unnecesary in future
    var userID: User.ID
    
    init(friendID: String, dateSend: String, dateAccept: String, isBlocked: String, isAccept: String, userID: User.ID) {
        self.friendID = friendID
        self.dateSend = dateSend
        self.dateAccept = dateAccept
        self.isBlocked = isBlocked
        self.isAccept = isAccept
        self.userID = userID
    }
}

/// Uncomment to use instead of MySQLModel extension below, but which is using is better more than code in comment.
//extension Acronym: Model {
//    typealias  Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id
//}

//extension Acronym: MySQLModel {}
extension Friend: MySQLModel {
    typealias Database = MySQLDatabase
}
//extension Acronym: Migration {}
extension Friend: Content {}
extension Friend: Parameter {}

//MARK: Help to get users of acronyms.
extension Friend {
    var user: Parent<Friend, User> {
        return parent(\.userID)
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

//MARK: Foreign key constraints.
///     Using foreign key constraints has a number of benefits:
///     It ensures you can’t create acronyms with users that don’t exist.
///     You can’t delete users until you’ve deleted all their acronyms.
///     You can’t delete the user table until you’ve deleted the acronym table.
extension Friend: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}



