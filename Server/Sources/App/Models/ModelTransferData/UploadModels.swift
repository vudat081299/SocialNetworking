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
