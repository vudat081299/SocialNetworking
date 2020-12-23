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
        tokenAuthGroup.put(Post.parameter, use: putCommentID)
        tokenAuthGroup.delete(Post.parameter, use: deleteCommentID)
    }
    
    func postComment(_ req: Request, data: PostCreateComment) throws -> Future<BaseResponse<Comment>> {
        let user = try req.requireAuthenticated(User.self)
        let comment = try Comment(
            content: data.content,
            date: data.date,
            time: data.time,
            postID: data.postID,
            owner: user.requireID())
        return comment.save(on: req).map(to: BaseResponse<Comment>.self) { BaseResponse<Comment>(code: .ok, data: $0) }
    }
    
    func getAllComments(_ req: Request) throws -> Future<BaseResponse<[Comment]>> {
        return Comment
            .query(on: req)
            .all().map(to: BaseResponse<[Comment]>.self) { BaseResponse<[Comment]>(code: .ok, data: $0) }
    }
    
    func putCommentID(_ req: Request) throws -> Future<BaseResponse<Comment>> {
        return try flatMap(
            to: BaseResponse<Comment>.self,
            req.parameters.next(Comment.self),
            req.content.decode(PostCreateComment.self)) { comment, updatedComment in
                comment.content = updatedComment.content
                comment.date = updatedComment.date
                comment.time = updatedComment.time
                comment.postID = updatedComment.postID
                let user = try req.requireAuthenticated(User.self)
                comment.owner = try user.requireID()
            return comment.save(on: req).map(to: BaseResponse<Comment>.self) { BaseResponse<Comment>(code: .ok, data: $0) }
        }
    }
    
    func deleteCommentID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Post.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

struct PostCreateComment: Content {
    let content: String
    let date: String
    let time: String
    let postID: Post.ID
}

//struct ResponseMessageFormSendingReq: Content {
//    var identityName: String
//    var status: Int
//    var message: String
//}

