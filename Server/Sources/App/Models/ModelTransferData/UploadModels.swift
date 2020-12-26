//
//  UploadModels.swift
//  App
//
//  Created by Vũ Quý Đạt  on 25/12/2020.
//

import Vapor

struct PostCreatedUser: Content {
    let name: String
    let username: String
    let password: String
    let file: File?
    let email: String?
    let phonenumber: String?
    let idDevice: String?
}

struct PostUpdateUser: Content {
    let name: String
    let username: String
    let file: File?
    let email: String?
    let phonenumber: String?
    let idDevice: String?
}

struct PostUpdateUserPassword: Content {
    let password: String
}

struct PostCreateComment: Content {
    let content: String
    let date: String
    let time: String
    let postID: Post.ID
}

struct FriendCreateData: Content {
    let friendID: String
    let dateSend: String
    let dateAccept: String?
    let isBlocked: String?
    let isAccept: String?
}

struct PostCreateData: Content {
    let date: String
    let time: String
    let content: String
    let typeMedia: String? // 0 is image 1 is video
    let video: String?
    let image: String?
    let extend: String
    let file: [File] // ? has error cannot get file when have optional type
    let like: Int?
}
