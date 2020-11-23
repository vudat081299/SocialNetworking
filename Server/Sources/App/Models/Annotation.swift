//
//  Annotation.swift
//  App
//
//  Created by Vũ Quý Đạt  on 23/11/2020.
//

import Vapor
import FluentMySQL

final class Annotation: Codable {
    var id: Int?
    var latitude: Double
    var longitude: Double
    var name: String
    var description: String
    var image: String
    
    
    init(latitude: Double, longitude: Double, name: String, description: String, image: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.description = description
        self.image = image
    }
}

extension Annotation: MySQLModel {
    typealias Database = MySQLDatabase
}

extension Annotation: Content {}
extension Annotation: Parameter {}
extension Annotation: Migration {}
