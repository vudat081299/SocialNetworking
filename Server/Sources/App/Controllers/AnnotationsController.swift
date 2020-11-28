//
//  AnnotationsController.swift
//  App
//
//  Created by Vũ Quý Đạt  on 23/11/2020.
//

import Foundation
import Vapor
import Fluent
import Authentication

var shouldUpdate = false // should update data on client

struct AnnotationsController: RouteCollection {
    
    
    let annotationMediaUploaded = "AnnotationMediaUploaded/"
    
    let suffixImage = ".png"
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "annotations")
//        let tokenAuthMiddleware = User.tokenAuthMiddleware()
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        acronymsRoutes.get(use: getAllAnnotations)
        acronymsRoutes.get("checkdata", use: checkData)
        acronymsRoutes.post(AnnotationCreateData.self, use: postAnnotation)
        acronymsRoutes.get("data", use: getAllAnnotationsData)
//        acronymsRoutes.put(Post.parameter, use: putCommentID)
        acronymsRoutes.delete(Annotation.parameter, use: deleteCommentID)
    }
    
    func postAnnotation(_ req: Request, data: AnnotationCreateData) throws -> Future<Annotation> {
        shouldUpdate = true
        let annotation = Annotation(
            latitude: data.latitude,
            longitude: data.longitude,
            name: data.name,
            description: data.description!)
        
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + annotationMediaUploaded
        let folderPath = mediaUploadedPath + ""
//        let fileName = "\(data.name)\(suffixImage)"
//        let filePath = folderPath + fileName
        
        return annotation.save(on: req).map { subAnnotation in
            let fileName = "\(subAnnotation.id ?? 9999)\(suffixImage)"
            let filePath = folderPath + fileName
            FileManager().createFile(atPath: filePath,
                                     contents: data.file.data,
                                     attributes: nil)
            print(filePath)
            return subAnnotation
        }
    }
//
//    func getAllAnnotations(_ req: Request) throws -> Future<ReponseGetAnnotation> {
//        return Annotation
//            .query(on: req)
//            .all()
//            .map(to: ReponseGetAnnotation.self) { annotation in
//                let workPath = try req.make(DirectoryConfig.self).workDir
//                let mediaUploadedPath = workPath + annotationMediaUploaded
//                let folderPath = mediaUploadedPath + ""
////                let fileName = "\(annotation.name)\(suffixImage)"
////                let filePath = folderPath + fileName
////                let data = try Data(content sOfDirectory: URL(fileURLWithPath: folderPath))
////                let dđ = contentsOf
//                var fileURLs: [URL]?
//                let fileManager = FileManager.default
////                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//                do {
//                    fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: folderPath), includingPropertiesForKeys: nil)
//                    // process files
//                } catch {
////                    print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
//                }
//                print(folderPath)
//                var listFile = [Data]()
//                for d in fileURLs! {
//                    listFile.append(try Data(contentsOf: d))
//                }
//                return ReponseGetAnnotation(annotation: annotation, image: listFile)
//            }
//    }
    
    func getAllAnnotations(_ req: Request) throws -> Future<[Annotation]> {
        print("getting annotations data!")
        return Annotation
            .query(on: req)
            .all()
    }
    
    func getAllAnnotationsData(_ req: Request) throws -> Future<[AnnotationData]> {
        print("getting annotations data!")
        shouldUpdate = false
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + annotationMediaUploaded
        let folderPath = mediaUploadedPath + ""
        return Annotation
            .query(on: req)
            .all()
            .map(to: [AnnotationData].self) { annotation in
                var fileURLs: [URL]?
                let fileManager = FileManager.default
                do {
                    fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: folderPath), includingPropertiesForKeys: nil)
                } catch {
                }
                var annotationDatas = [AnnotationData]()
                for e in fileURLs! {
                    let subE = e.absoluteString.reversed()
                    let fileName = String((String(subE[..<subE.firstIndex(of: "/")!])).reversed())
                    let annotationData = AnnotationData(annotationImageName: fileName, image: try Data(contentsOf: e))
//                    annotationData += an
                    annotationDatas.append(annotationData)
                }
                return annotationDatas
            }
    }
    
    func checkData (_ req: Request) throws -> ResponseCheckData {
        return ResponseCheckData(shouldUpdate: shouldUpdate)
    }
    
    func getCategoriesOfAcronym(_ req: Request) throws -> Future<[Category]> {
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: [Category].self) { acronym in
                try acronym
                    .categories
                    .query(on: req)
                    .all()
        }
    }
    
//    func getMediaData(_ req: Request) throws -> Future<[File]> {
////        let res = req.makeResponse()
////        let user = User(name: "Vapor", age: 3, image: Data(...), isAdmin: false)
////        res.content.encode(user, as: .formData)
//        return try flat
////        return Annotation
////            .query(on: req)
////            .all()
//    }
    
    
    
//    func putCommentID(_ req: Request) throws -> Future<Comment> {
//        return try flatMap(
//            to: Comment.self,
//            req.parameters.next(Comment.self),
//            req.content.decode(PostCreateComment.self)) { comment, updatedComment in
//                comment.content = updatedComment.content
//                comment.date = updatedComment.date
//                comment.time = updatedComment.time
//                comment.postID = updatedComment.postID
//                let user = try req.requireAuthenticated(User.self)
//                comment.owner = try user.requireID()
//                return comment.save(on: req)
//        }
//    }
    
    func deleteCommentID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Annotation.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

struct AnnotationCreateData: Content {
    let latitude: String
    let longitude: String
    let name: String
    let description: String?
    let file: File
}

struct AnnotationData: Content {
    var annotationImageName: String
    var image: Data
}

struct ReponseGetAnnotation: Content {
    var annotationData: [AnnotationData]
}

struct ResponseCheckData: Content {
    var shouldUpdate: Bool
}

//extension FileManager {
//    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
//        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
//        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
//        return fileURLs
//    }
//}
