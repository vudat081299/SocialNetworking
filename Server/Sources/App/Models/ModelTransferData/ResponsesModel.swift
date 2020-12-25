//
//  ResponsesModel.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/12/2020.
//

import Vapor

// MARK: - Error
struct ResponseError: Content {
    let code: String
    let message: String
    let data = "Not exist!"
}

// MARK: - UserController
struct ReponseGetAllUser: Content {
    let code: String
    let message: String
    let data: [User.Public]
}

struct ResponseGetRoomsOfUserID: Content {
    let code: String
    let message: String
    let data: [Room]
}

struct ResponseCreateUser: Content {
    let code: String
    let message: String
    let data: User.Public
}

struct ResponseGetUserByID: Content {
    let code: String
    let message: String
    let data: User.Public
}

struct ResponseDeleteUserByID: Content {
    let code: String
    let message: String
    let data: User
}

struct ResponseGetAllPostOfUserByID: Content {
    let code: String
    let message: String
    let data: [Post]
}

struct ResponseGetAllFriendsOfUserID: Content {
    let code: String
    let message: String
    let data: [Friend]
}

struct ResponseUpdateUser: Content {
    let code: String
    let message: String
    let data: User.Public
}

struct ResponseLogin: Content {
    let code: String
    let message: String
    let data: Token
}
