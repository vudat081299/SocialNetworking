//
//  SaveSearch.swift
//  App
//
//  Created by Be More on 18/11/2020.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class SaveSearch: Content {
    var id: Int?
    var keyword: String
    var created: Date
    
    init(keyword: String, created: Date) {
        self.keyword = keyword
        self.created = created
    }
}


extension SaveSearch: MySQLModel {
    typealias Database = MySQLDatabase
}

extension SaveSearch: Migration {
}

extension SaveSearch: Parameter { }
