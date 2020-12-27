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
    let date: String?
    let time: String?
    let content: String?
    let typeMedia: String? // 0 is null 1 is image 2 is video
    let video: String?
    let image: String?
    let extend: String?
    let file: [File]
    let like: Int?
}

// MARK: - Ws
/// chatting
struct MessageForm: Decodable {
    let time: String
    let content: String
    let roomID: Int
    let from: String
    let to: String
}

// MARK: - Validations
extension PostCreatedUser: Validatable, Reflectable {
    static func validations() throws -> Validations<PostCreatedUser> {
        var validations = Validations(PostCreatedUser.self)
        
//        try validations.add(\.name, .ascii)
//        try validations.add(\.username, .alphanumeric && .count(3...))
//        try validations.add(\.password, .count(8...))
//
//        let name: String
//        let username: String
//        let password: String
//        let file: File?
//        let email: String?
//        let phonenumber: String?
        
//    validations.add("passwords match") { model in
//        guard model.password == model.confirmPassword else {
//            throw BasicValidationError("passwords don’t match")
//        }
//    }
        
        return validations
    }
}

extension PostUpdateUser: Validatable, Reflectable {
    static func validations() throws -> Validations<PostUpdateUser> {
        var validations = Validations(PostUpdateUser.self)
        
//        try validations.add(\.name, .ascii)
//        try validations.add(\.username, .alphanumeric && .count(3...))
//        try validations.add(\.password, .count(8...))
//
//        let name: String
//        let username: String
//        let password: String
//        let file: File?
//        let email: String?
//        let phonenumber: String?
        
//    validations.add("passwords match") { model in
//        guard model.password == model.confirmPassword else {
//            throw BasicValidationError("passwords don’t match")
//        }
//    }
        
        return validations
    }
}
