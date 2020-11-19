//
//  Message.swift
//  App
//
//  Created by Be More on 20/11/2020.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Message: Content {
    var id: UUID?
    var message: String
    var unread: Bool = false
    var created: Date

}
