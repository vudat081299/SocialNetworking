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
    var title: String
    var subTitle: String?
    var description: String?
    var imageNote: String?
    var type: String?
    var city: String?
    var country: String?
    
    init(latitude: String, longitude: String, title: String, subTitle: String, description: String, imageNote: String, type: String, city: String, country: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.subTitle = subTitle
        self.description = description
        self.imageNote = imageNote
        self.type = type
        self.city = city
        self.country = country
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
