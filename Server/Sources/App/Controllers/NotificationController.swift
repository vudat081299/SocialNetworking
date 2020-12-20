//
//  NotificationController.swift
//  App
//
//  Created by Be More on 23/11/2020.
//

import Foundation
import Vapor
import Fluent
import Authentication

struct NotificationController: RouteCollection {
    func boot(router: Router) throws {
        
        let notificationRouters = router.grouped("api/notification")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = notificationRouters.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(GetNotificationsBody.self, at: "", use: self.getNotification(_:_:))
        tokenAuthGroup.post(PostNotificationBody.self, at: "/push", use: self.pushNotification(_:_:))
        tokenAuthGroup.put(Notification.self, at: "/set_read_notification", use: self.setSeen(_:_:))
        
    }
    
    
    private func getNotification(_ request: Request, _ notiification: GetNotificationsBody) -> Future<[Notification]> {
        return  Notification.query(on: request).range(notiification.index ... notiification.count).all()
    }
    
    private func pushNotification(_ request: Request, _ bodyData: PostNotificationBody) -> Future<Notification> {
        
        let saveData = Notification(timestamp: bodyData.timestamp,
                                    type: bodyData.type,
                                    userId: bodyData.userId,
                                    fromUserId: bodyData.fromUserId,
                                    postId: bodyData.postId)
        return saveData.save(on: request)
    }
    
    private func setSeen(_ request: Request, _ bodyData: Notification) -> Future<Notification> {
        return bodyData.update(on: request)
    }
    
}

struct GetNotificationsBody: Content {
    let index: Int
    let count: Int
}

struct PostNotificationBody: Content {
    let timestamp: Date
    let type: Int
    let userId: User.ID
    let fromUserId: User.ID
    let postId: Post.ID
}
