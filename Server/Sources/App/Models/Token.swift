//
//  Token.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/09/2020.
//

import Foundation

import Vapor
import FluentSQLite
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

extension Token: Parameter {}

extension Token: SQLiteUUIDModel {
    typealias Database = SQLiteDatabase
}

extension Token: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
//            builder.unique(on: \.userID)
        }
    }
}

extension Token: Content {}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 64)
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID())
    }
    
    static func refresh(for user: User.ID) throws -> Token {
        let random = try CryptoRandom().generateData(count: 64)
        return Token(
            token: random.base64EncodedString(),
            userID: user)
    }
}

extension Token: Authentication.Token {
    static let userIDKey: UserIDKey = \Token.userID
    typealias UserType = User
}

extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}
