//import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

//extension Token: MySQLUUIDModel {}
extension Token: MySQLUUIDModel {
    typealias Database = MySQLDatabase
}

extension Token: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Token: Content {}

extension Token {
    // 1
    static func generate(for user: User) throws -> Token {
        // 2
        let random = try CryptoRandom().generateData(count: 128)
        // 3
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID())
    }
}/*
 1. Define a static function to generate a token for a user.
 2. Generate 16 random bytes to act as the token.
 3. Create a Token using the base64-encoded representation of the random bytes and the user’s ID.
 */

// 1
extension Token: Authentication.Token {
    // 2
    static let userIDKey: UserIDKey = \Token.userID
    // 3
    typealias UserType = User
}

// 4
extension Token: BearerAuthenticatable {
    // 5
    static let tokenKey: TokenKey = \Token.token
}/*
 1. Conform Token to Authentication’s Token protocol.
 2. Define the user ID key on Token.
 3. Tell Vapor what type the user is.
 4. Conform Token to BearerAuthenticatable. This allows you to use Token with bearer authentication.
 5. Tell Vapor the key path to the token key, in this case, Token’s token string.
 */
