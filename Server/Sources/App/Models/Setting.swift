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



struct DefaultSetting: Migration {
    // 2
    typealias Database = MySQLDatabase
    // 3
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        let setting = Setting(false, fromFriend: false, requestedFriend: false, suggestedFriend: false, birthday: false, video: false, report: false, soundOn: false, notificationOn: false, vibrantOn: false, ledOn: false)
        // 6
        return setting.save(on: connection).transform(to: ())
    }
    // 7
    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}
