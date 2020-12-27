//
//  CommentsController.swift
//  App
//
//  Created by Vũ Quý Đạt  on 22/11/2020.
//

import Vapor
import Fluent
import Authentication

struct CommentsController: RouteCollection {
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "comments")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.get(use: getAllComments)
        tokenAuthGroup.post(PostCreateComment.self, use: postComment)
        tokenAuthGroup.put(Comment.parameter, use: putCommentID)
        tokenAuthGroup.delete(Comment.parameter, use: deleteCommentID)
    }
    
    func postComment(_ req: Request, data: PostCreateComment) throws -> Future<ResponsePostComment> {
        let user = try req.requireAuthenticated(User.self)
        let comment = try Comment(
            content: data.content,
            date: data.date,
            time: data.time,
            postID: data.postID,
            owner: user.requireID())
        return comment.save(on: req).map(to: ResponsePostComment.self) { savedComment in
            sessionManager.notify(to: String(savedComment.owner), content: "\(user.name) has comment your post!")
            return ResponsePostComment(code: 1000, message: "Comment on a post successful!", data: savedComment)
        }
    }
    
    func getAllComments(_ req: Request) throws -> Future<[Comment]> {
        return Comment
            .query(on: req)
            .all()
    }
    
    func putCommentID(_ req: Request) throws -> Future<ResponseEditComment> {
        return try flatMap(
            to: ResponseEditComment.self,
            req.parameters.next(Comment.self),
            req.content.decode(PostCreateComment.self)) { comment, updatedComment in
                comment.content = updatedComment.content
                comment.date = updatedComment.date
                comment.time = updatedComment.time
                comment.postID = updatedComment.postID
                let user = try req.requireAuthenticated(User.self)
                comment.owner = try user.requireID()
            return comment.save(on: req).map(to: ResponseEditComment.self) { editedComment in
                return ResponseEditComment(code: 1000, message: "Edit comment successful!", data: editedComment)
            }
        }
    }
    
    // original
//    func deleteCommentID(_ req: Request) throws -> Future<HTTPStatus> {
//        return try req
//            .parameters
//            .next(Post.self)
//            .delete(on: req)
//            .transform(to: .noContent)
//    }
    func deleteCommentID(_ req: Request) throws -> Future<ResponseDeleteComment> {
        return try req
            .parameters
            .next(Comment.self)
            .delete(on: req)
            .map(to: ResponseDeleteComment.self) { comment in
                return ResponseDeleteComment(code: 1000, message: "Delete comment successful!", data: comment)
            }
    }
    
}

//struct ResponseMessageFormSendingReq: Content {
//    var identityName: String
//    var status: Int
//    var message: String
//}

