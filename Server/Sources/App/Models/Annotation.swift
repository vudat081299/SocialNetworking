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
    var latitude: String
    var longitude: String
    var name: String
    var description: String
    var image: String
    
    
    init(latitude: String, longitude: String, name: String, description: String, image: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.description = description
        self.image = image
    }
    
//    final class Public: Codable {
//        var id: Int?
//        var latitude: Double
//        var longitude: Double
//        var name: String
//        var description: String
//        var image: String
//        var file: File
//        
//        init(id: Int?, latitude: Double, longitude: Double, name: String, description: String, image: String) {
//            self.id = id
//            self.latitude = latitude
//            self.longitude = longitude
//            
//            self.name = name
//            self.description = description
//            self.image = image
//            
//            let workPath = FileManager.default.currentDirectoryPath
//            let mediaUploadedPath = workPath + "AnnotationMediaUploaded/"
//            let folderPath = mediaUploadedPath + ""
//            let fileName = "\(name)\(".png")"
//            let filePath = folderPath + fileName
//            
//            self.file.data = try Data(contentsOf: URL(string: filePath)!)
//        }
//    }
}

extension Annotation: MySQLModel {
    typealias Database = MySQLDatabase
}

extension Annotation: Content {}
extension Annotation: Parameter {}
extension Annotation: Migration {}
