//
//  AnnotationsController.swift
//  App
//
//  Created by Vũ Quý Đạt  on 23/11/2020.
//

import Vapor
import Fluent
import Authentication

struct AnnotationsController: RouteCollection {
    
    let annotationMediaUploaded = "AnnotationMediaUploaded/"
    
    let suffixImage = ".png"
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "annotations")
//        let tokenAuthMiddleware = User.tokenAuthMiddleware()
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        acronymsRoutes.get(use: getAllAnnotations)
        acronymsRoutes.post(AnnotationCreateData.self, use: postAnnotation)
//        acronymsRoutes.put(Post.parameter, use: putCommentID)
//        acronymsRoutes.delete(Post.parameter, use: deleteCommentID)
    }
    
    func postAnnotation(_ req: Request, data: AnnotationCreateData) throws -> Future<Annotation> {
        let annotation = Annotation(
            latitude: data.latitude,
            longitude: data.longitude,
            name: data.name,
            description: data.description!,
            image: data.image)
        
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + annotationMediaUploaded
        let folderPath = mediaUploadedPath + ""
        let fileName = "\(data.name)\(suffixImage)"
        let filePath = folderPath + fileName
        
        print(filePath)
        
        FileManager().createFile(atPath: filePath,
                                 contents: data.file.data,
                                 attributes: nil)
        
        return annotation.save(on: req)
    }
    
    func getAllAnnotations(_ req: Request) throws -> Future<[Annotation]> {
        return Annotation
            .query(on: req)
            .all()
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
            .next(Post.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

struct AnnotationCreateData: Content {
    let latitude: Double
    let longitude: Double
    let name: String
    let description: String?
    let image: String
    let file: File
}

//struct ResponseMessageFormSendingReq: Content {
//    var identityName: String
//    var status: Int
//    var message: String
//}

