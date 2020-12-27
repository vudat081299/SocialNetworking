import Vapor
import FluentMySQL

final class Post: Codable {
    var id: Int?
    var date: String
    var time: String
    var content: String
    var typeMedia: String?
    var video: String? // path
    var image: String? // path
    var extend: String? // type file
    var userID: User.ID
    var like: Int
    
    init(date: String, time: String, content: String, typeMedia: String? = nil, video: String? = nil, image: String? = nil, extend: String? = nil, like: Int = 0, userID: User.ID) {
        self.date = date
        self.time = time
        self.content = content
        self.typeMedia = typeMedia
        self.video = video
        self.image = image
        self.extend = extend
        self.userID = userID
        self.like = like
    }
}

/// Uncomment to use instead of MySQLModel extension below, but which is using is better more than code in comment.
//extension Acronym: Model {
//    typealias  Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id
//}

//extension Acronym: MySQLModel {}
extension Post: MySQLModel {
    typealias Database = MySQLDatabase
}
//extension Acronym: Migration {}
extension Post: Content {}
extension Post: Parameter {}

//MARK: Help to get users of acronyms.
extension Post {
    var user: Parent<Post, User> {
        return parent(\.userID)
    }
    var comments: Children<Post, Comment> {
        return children(\.postID)
    }
    
    var notifiation: Children<Post, Notification> {
        return children(\.postId)
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
extension Post: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}



