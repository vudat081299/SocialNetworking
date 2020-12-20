//import Foundation
import Vapor
import FluentMySQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String
    ///This stores an optional String for the image. It will contain the filename of the user’s profile picture on disk. The filename is optional as you’re not enforcing that a user has a profile picture — and they won’t have one when they register.
    var profilePicture: String? // path
    var email: String?
    var phonenumber: String?
    var idDevice: String?
    
    // Providing a default value of nil for profilePicture allows your app to continue to compile and operate without further source changes.
    init(name: String, username: String, password: String, profilePicture: String? = nil, email: String? = nil, phonenumber: String? = nil, idDevice: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        
        self.profilePicture = profilePicture
        self.email = email
        self.phonenumber = phonenumber
        self.idDevice = idDevice
    }
    
    /// This creates an inner class to represent a public view of User.
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        var profilePicture: String?
        var email: String?
        var phonenumber: String?
        var idDevice: String?
        
        init(id: UUID?, name: String, username: String, profilePicture: String? = nil, email: String? = nil, phonenumber: String? = nil, idDevice: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            
            self.profilePicture = profilePicture
            self.email = email
            self.phonenumber = phonenumber
            self.idDevice = idDevice
        }
    }
}

//extension User: MySQLUUIDModel {}
extension User: MySQLUUIDModel {
    typealias Database = MySQLDatabase
}

extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {} /// This conforms User.Public to Content, allowing you to return the public view in responses.

//MARK: help to get acronyms of users
extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
    
    var posts: Children<User, Post> {
        return children(\.userID)
    }
    
    var friends: Children<User, Friend> {
        return children(\.userID)
    }
    
    var notifiations: Children<User, Notification> {
        return children(\.userId)
    }
    
    var conversations: Children<User, Conversation> {
        return children(\.fromUId)
    }
}

/// This implements a custom migration, much like adding foreign key constraints in Chapter 9, “Parent Child Relationships".
extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        // 1
        return Database.create(self, on: connection) { builder in
            // 2
            try addProperties(to: builder)
            // 3
            builder.unique(on: \.username)
        }
    }/*
     1. Create the User table.
     2. Add all the columns to the User table using User’s properties.
     3. Add a unique index to username on User.
     */
}

extension User {
    // 1
    func convertToPublic() -> User.Public {
        // 2
        return User.Public(id: id, name: name, username: username, profilePicture: profilePicture, email: email, phonenumber: phonenumber, idDevice: idDevice)
    }
}/*
 1. Define a method on User that returns User.Public.
 2. Create a public version of the current object.
 */

extension Future where T: User {
    // 2
    func convertToPublic() -> Future<User.Public> {
        // 3
        return self.map(to: User.Public.self) { user in
            // 4
            return user.convertToPublic()
        }
    }
}/*
 1. Define an extension for Future<User>.
 2. Define a new method that returns a Future<User.Public>.
 3. Unwrap the user contained in self.
 4. Convert the User object to User.Public.
 */

// 1
extension User: BasicAuthenticatable {
    // 2
    static let usernameKey: UsernameKey = \User.username
    // 3
    static let passwordKey: PasswordKey = \User.password
}/*
 1. Conform User to BasicAuthenticatable.
 2. Tell Vapor which key path of User is the username.
 3. Tell Vapor which key path of User is the password.
 */

// 1
extension User: TokenAuthenticatable {
    // 2
    typealias TokenType = Token
}/*
 1. Conform User to TokenAuthenticatable. This allows a token to authenticate a user.
 2. Tell Vapor what type a token is.
 */


//MARK: Database seeding
// At this point the API is secure, but now there’s another problem. When you deploy your application, or next revert the database, you won’t have any users in the database.
// But, you can’t create a new user since that route requires authentication! One way to solve this is to seed the database and create a user when the application first boots up. In Vapor, you do this with a migration.
// 1
struct AdminUser: Migration {
    // 2
    typealias Database = MySQLDatabase
    // 3
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        // 4
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        // 5
        let user = User(name: "Admin", username: "admin", password: hashedPassword)
        // 6
        return user.save(on: connection).transform(to: ())
    }
    // 7
    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}/*
 1. Define a new type that conforms to Migration.
 2. Define which database type this migration is for.
 3. Implement the required prepare(on:).
 4. Create a password hash and terminate with a fatal error if this fails.
 5. Create a new user with the name Admin, username admin and the hashed password.
 6. Save the user and transform the result to Void, the return type of prepare(on:).
 7. Implement the required revert(on:). .done(on:) returns a pre-completed Future<Void>.
 */

// 1
extension User: PasswordAuthenticatable {}
// 2
extension User: SessionAuthenticatable {}
/*
 1. Conform User to PasswordAuthenticatable. This allows Vapor to authenticate users with a username and password when they log in. Since you’ve already implemented the necessary properties for PasswordAuthenticatable in BasicAuthenticatable, there’s nothing to do here.
 2. Conform User to SessionAuthenticatable. This allows the application to save and retrieve your user as part of a session.
 */
