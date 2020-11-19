//
//  Setting.swift
//  App
//
//  Created by Be More on 19/11/2020.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Setting: Content {
    var id: Int?
    var likeComment: Bool
    var fromFriend: Bool
    var requestedFriend: Bool
    var suggestedFriend: Bool
    var birthday: Bool
    var video: Bool
    var report: Bool
    var soundOn: Bool
    var notificationOn: Bool
    var vibrantOn: Bool
    var ledOn: Bool
    
    init (_ likeComment: Bool, fromFriend: Bool, requestedFriend: Bool, suggestedFriend: Bool, birthday: Bool, video: Bool, report: Bool, soundOn: Bool, notificationOn: Bool , vibrantOn: Bool, ledOn: Bool) {
        self.likeComment = likeComment
        self.fromFriend = fromFriend
        self.requestedFriend = requestedFriend
        self.suggestedFriend = suggestedFriend
        self.birthday = birthday
        self.video = video
        self.report = report
        self.soundOn = soundOn
        self.notificationOn = notificationOn
        self.vibrantOn = vibrantOn
        self.ledOn = ledOn
    }
}


extension Setting: MySQLModel {
    typealias Database = MySQLDatabase
}

extension Setting: Migration {
}

extension Setting: Parameter { }
