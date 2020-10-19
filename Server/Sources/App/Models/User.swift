//
//  User.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/09/2020.
//

import Foundation

import Vapor
import FluentSQLite
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var phoneNumber: String?

    var username: String
    var password: String


    init(name: String, phoneNumber: String? = nil, username: String, password: String) {
        self.name = name
        self.phoneNumber = phoneNumber
        
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: UUID?
        var name: String
        var phoneNumber: String
        
        var username: String

        init(id: UUID?, name: String, phoneNumber: String? = "", username: String) {
            self.id = id
            self.name = name
            self.phoneNumber = phoneNumber ?? ""
            
            self.username = username

        }
    }
}

extension User: SQLiteUUIDModel {
    typealias Database = SQLiteDatabase
}

extension User: Content {}

extension User: Parameter {}

extension User.Public: Content {}

extension User: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, phoneNumber: phoneNumber, username: username)
    }
}
extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

struct AdminUser: Migration {
    typealias Database = SQLiteDatabase
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        let password = try? BCrypt.hash("vudat81299")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        let user = User(name: "vudat81299", username: "vudat81299", password: hashedPassword)
        return user.save(on: connection).transform(to: ())
    }
    static func revert(on connection: SQLiteConnection) -> Future<Void> {
        return .done(on: connection)
    }
}

extension User: PasswordAuthenticatable {}

extension User: SessionAuthenticatable {}
