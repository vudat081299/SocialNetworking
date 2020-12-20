//
//  ConversationController.swift
//  App
//
//  Created by Be More on 24/11/2020.
//

import Foundation
import Vapor
import Fluent
import Authentication

struct ConversationController: RouteCollection {
    func boot(router: Router) throws {
        let conversationRouters = router.grouped("api/conversation")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = conversationRouters.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(Conversation.self, at: "", use: self.createConversation(_:_:))
        tokenAuthGroup.get("/get_conversations", User.parameter, use: self.getAllConversations(_:))
        tokenAuthGroup.get("/get_message", Conversation.parameter, use: self.getAllConversations(_:))
    }
    
    private func createConversation(_ request: Request, _ conversation: Conversation) -> Future<Conversation> {
        return conversation.save(on: request)
    }
    
    private func getAllConversations(_ request: Request) throws -> Future<[Conversation]> {
        let user = try request.requireAuthenticated(User.self)
        return Conversation.query(on: request).filter(\.fromUId == user.id!).all()
    }
    
    private func getAllMessages(_ request: Request) throws -> Future<[Message]> {
        let conversation = try request.parameters.next(Conversation.self)
        return Message.query(on: request).filter(\.id! == conversation.messageId).all()
    }
}
