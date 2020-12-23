//
//  RoomsController.swift
//  App
//
//  Created by Vũ Quý Đạt  on 23/12/2020.
//

import Vapor
import Crypto

struct MessagesController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let messagesRoute = router.grouped("api", "messages")
        messagesRoute.get(use: getAllMessages)
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = messagesRoute.grouped(basicAuthMiddleware)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = messagesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    }
    
    func getAllMessages(_ req: Request) throws -> Future<[Message]> {
        return Message
            .query(on: req)
            .decode(data: Message.self)
            .all()
    }
}
