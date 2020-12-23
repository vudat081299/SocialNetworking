//
//  MessageController.swift
//  App
//
//  Created by Be More on 24/11/2020.
//

import Foundation
import Vapor
import Fluent
import Authentication

struct MessageController: RouteCollection {
    
    func boot(router: Router) throws {
        let messageRouters = router.grouped("api/message")
        
        messageRouters.get(use: getAllMessages)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = messageRouters.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(Message.self, at: "", use: self.sendMessage(_:_:))
    }
    
    
    private func sendMessage(_ request: Request, _ message: Message) -> Future<Message> {
        return message.save(on: request)
    }
    
    func getAllMessages(_ req: Request) throws -> Future<[Message]> {
        return Message
            .query(on: req)
            .all()
    }
    
}
