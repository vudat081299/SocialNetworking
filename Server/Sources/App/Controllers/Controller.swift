//
//  Controller.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/09/2020.
//

import Foundation

import Vapor
import Fluent
import Authentication

struct Controller: RouteCollection {
    func boot(router: Router) throws {
        let basicRoute = router.grouped("server")
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//        let basicAuthGroup = basicRoute.grouped(basicAuthMiddleware)
//        let tokenAuthMiddleware = User.tokenAuthMiddleware()
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        let tokenAuthGroup = basicRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
//
//        basicAuthGroup.post("login", use: login)
////        basicAuthGroup.post(Login.self, at: "login", use: login) // 0x0000_0000
//
        basicRoute.post(User.self, at: "createUser", use: createUser)
        basicRoute.get("getAllUsers", use: getAllUsers)
//        tokenAuthGroup.post("logout", use: logout)
        
        let basicAuthMiddleware =
          User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = basicRoute.grouped(basicAuthMiddleware)
        // 2
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
      // 2
      let user = try req.requireAuthenticated(User.self)
      // 3
      let token = try Token.generate(for: user)
      // 4
      return token.save(on: req)
    }
    
    func createUser(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req)
            .convertToPublic()
    }
    
    func getAllUsers(_ req: Request) throws -> Future<[User.Public]> {
        return User
            .query(on: req)
            .decode(data: User.Public.self)
            .all()
    }
    
//    , _ login: Login // extra param // 0x0000_0000
    func login(_ req: Request) throws -> Future<Token> {
        // more flexible
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
        
//        return User.authenticate(username: login.username,
//                                 password: login.password,
//                                 using: BCryptDigest(),
//                                 on: req)
//            .flatMap(to: Token.self) { user in
//                guard let user = user else {
//                    throw Abort(.notFound, reason: "Invalid username or password!")
//                }
//                let token = try Token.generate(for: user)
//                return token.save(on: req)
//        }
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.requireAuthenticated(Token.self).delete(on: req).map(to: HTTPStatus.self) {
            return .ok
        }
    }
}

struct Login: Content {
    var username: String
    var password: String
}
