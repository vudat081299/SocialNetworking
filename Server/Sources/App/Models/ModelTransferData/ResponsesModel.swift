//
//  ResponsesModel.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/12/2020.
//

import Vapor

protocol BasicResponse: Content {
    var code: Int { get }
    var message: String { get }
}

// MARK: - Error
struct ResponseError: BasicResponse {
    let code: Int
    let message: String
    var data = "Not exist!"
}

// MARK: - UserController
struct ResponseGetAllUser: BasicResponse {
    let code: Int
    let message: String
    let data: [User.Public]
}

struct ResponseGetRoomsOfUserID: BasicResponse {
    let code: Int
    let message: String
    let data: [Room]
}

struct ResponseCreateUser: BasicResponse {
    let code: Int
    let message: String
    let data: User.Public
}

struct ResponseGetUserByID: BasicResponse {
    let code: Int
    let message: String
    let data: User.Public
}

struct ResponseDeleteUserByID: BasicResponse {
    let code: Int
    let message: String
    let data: User
}

struct ResponseGetAllPostOfUserByID: BasicResponse {
    let code: Int
    let message: String
    let data: [Post]
}

struct ResponseGetAllFriendsOfUserID: BasicResponse {
    let code: Int
    let message: String
    let data: [Friend]
}

struct ResponseUpdateUser: BasicResponse {
    let code: Int
    let message: String
    let data: User.Public
}

struct ResponseLogin: BasicResponse {
    let code: Int
    let message: String
    let data: Token
}

struct ResponseSearchUsers: BasicResponse {
    let code: Int
    let message: String
    let data: [User.Public]
}

// MARK: - FriendsController
struct ResponseFriendRequest: Content {
    let code: Int
    let message: String
    let data: Friend
}

struct ResponseGetAllFriends: Content {
    let code: Int
    let message: String
    let data: [Friend]
}

struct ResponseUpdateFriend: BasicResponse {
    let code: Int
    let message: String
    let data: Friend
}

struct ResponseDeleteFriend: BasicResponse {
    let code: Int
    let message: String
    let data: Friend
}

// MARK: - CommentsController
struct ResponsePostComment: BasicResponse {
    let code: Int
    let message: String
    let data: Comment
}

struct ResponseEditComment: BasicResponse {
    let code: Int
    let message: String
    let data: Comment
}

struct ResponseDeleteComment: BasicResponse {
    let code: Int
    let message: String
    let data: Comment
}

// MARK: - RoomsController
struct ResponseGetMessagesOfRoomID: BasicResponse {
    let code: Int
    let message: String
    let data: [Message]
}

struct ResponseGetAllRooms: BasicResponse {
    let code: Int
    let message: String
    let data: [Room]
}

// MARK: - PostsController
struct ResponsePostPost: BasicResponse {
    let code: Int
    let message: String
    let data: Post
}

struct ResponseGetCommentOfPost: BasicResponse {
    let code: Int
    let message: String
    let data: [Comment]
}

struct ResponseEditPost: BasicResponse {
    let code: Int
    let message: String
    let data: Post
}

struct ResponseLikeUpdate: BasicResponse {
    let code: Int
    let message: String
    let data: Post
}

struct ResponseDeletePost: BasicResponse {
    let code: Int
    let message: String
    let data: Post
}
