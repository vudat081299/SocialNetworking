import Vapor
import Fluent
import Authentication
import Foundation

struct PostsController: RouteCollection {
    
    let mediaUploaded = "AnnotationMediaUploaded/"
    
    let errorDataOfUrlMessage = "Invalid URL!"
    
    let suffixImage = ".png"
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "posts")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.get(use: getAllPosts)
        tokenAuthGroup.post(SearchData.self, use: getPosts)
        tokenAuthGroup.post(PostCreateData.self, use: postPost)
        tokenAuthGroup.put(Post.parameter, use: putPostID)
        tokenAuthGroup.put(Post.parameter, "likePostID", use: likedUpdate)
        tokenAuthGroup.delete(Post.parameter, use: deletePostID)
        
        //MARK: Get comments.
        tokenAuthGroup.get(Post.parameter, "comments", use: getCommentsOfPostID)
        tokenAuthGroup.get(Post.parameter, "media", use: getPostMedia)
    }
    
//    func test(_ req: Request, data: Test) throws -> ResponseMessageFormSendingReq {
//
//        let workPath = try req.make(DirectoryConfig.self).workDir
//        let mediaUploadedPath = workPath + mediaUploaded
//        let userDataPath = try mediaUploadedPath
//        var fileName = ""
//        fileName = try "test\(suffixImage)"
//        let fileInUserDataPath = userDataPath + fileName
//        FileManager().createFile(atPath: fileInUserDataPath,
//                                 contents: data.file.data,
//                                 attributes: nil)
//        print(userDataPath)
//        print(fileName)
//        var responseSuccessMessage = ResponseMessageFormSendingReq(identityName: "user.name", status: 0, message: "All input link is invalid!")
//
//            responseSuccessMessage = ResponseMessageFormSendingReq(identityName: "user.username", status: 1, message: "Success!")
//
//        return responseSuccessMessage
//
//    }
//
    
//    func postPost(_ req: Request, data: PostCreateData) throws -> Future<ResponsePostPost> {
//        let user = try req.requireAuthenticated(User.self)
//        let post = try Post(
//            date: data.date,
//            time: data.time,
//            content: data.content,
//            typeMedia: data.typeMedia,
//            video: data.video,
//            image: data.image,
//            like: 0,
//            userID: user.requireID())
//
//        let workPath = try req.make(DirectoryConfig.self).workDir
//        let mediaUploadedPath = workPath + mediaUploaded
//        let folderPath = try mediaUploadedPath + "\(user.requireID())/"
//        let fileName = "\(data.image!)\(suffixImage)"
//        let filePath = folderPath + fileName
//
//        if !FileManager().fileExists(atPath: folderPath) {
//            do {
//                try FileManager().createDirectory(atPath: folderPath,
//                                                  withIntermediateDirectories: true,
//                                                  attributes: nil)
//            } catch {
//                throw Abort(.badRequest, reason: "\(error.localizedDescription)")
//            }
//            FileManager().createFile(atPath: filePath,
//                                     contents: data.file.data,
//                                     attributes: nil)
//        } else {
//            FileManager().createFile(atPath: filePath,
//                                     contents: data.file.data,
//                                     attributes: nil)
//        }
//
//        return post.save(on: req).map(to: ResponsePostPost.self) { savedPost in
//            return ResponsePostPost(code: 1000, message: "Creat a post successful!", data: savedPost)
//        }
//    }
    func postPost(_ req: Request, data: PostCreateData) throws -> Future<ResponsePostPost> {
        let user = try req.requireAuthenticated(User.self)
        let post = try Post(
            date: data.date,
            time: data.time,
            content: data.content,
            typeMedia: data.typeMedia,
            like: 0,
            userID: user.requireID())
        
        return post.save(on: req).map(to: ResponsePostPost.self) { savedPost in
            let workPath = try req.make(DirectoryConfig.self).workDir
            let mediaUploadedPath = workPath + mediaUploaded
            let folderPath = mediaUploadedPath + "\(savedPost.id!)/"
//            for i in data.file! {
//                try i.write(to: folderPath)
//            }
            if data.file != nil && data.file.count > 0 {
                for (index, value) in data.file.enumerated() {
                    let fileName = "\(index)\(suffixImage)"
                    let filePath = folderPath + fileName
                    
                    if !FileManager().fileExists(atPath: folderPath) {
                        do {
                            try FileManager().createDirectory(atPath: folderPath,
                                                              withIntermediateDirectories: true,
                                                              attributes: nil)
                        } catch {
                            throw Abort(.badRequest, reason: "\(error.localizedDescription)")
                        }
                        FileManager().createFile(atPath: filePath,
                                                 contents: value.data,
                                                 attributes: nil)
                    } else {
                        FileManager().createFile(atPath: filePath,
                                                 contents: value.data,
                                                 attributes: nil)
                    }
                }
            }
            return ResponsePostPost(code: 1000, message: "Create a post successful!", data: savedPost.id!)
        }
    }
//
//    struct MyPayload: Content {
//        var somefiles: [File]
//    }
//
//    func myUpload(_ req: Request) -> Future<HTTPStatus> {
//        let user = try req.requireAuthenticated(User.self)
//        return try req.content.decode(MyPayload.self).flatMap { payload in
//            let workDir = DirectoryConfig.detect().workDir
//            return payload.somefiles.map { file in
//                let url = URL(fileURLWithPath: workDir + localImageStorage + file.filename)
//                try file.data.write(to: url)
//                return try Image(userID: user.requireID(), url: imageStorage + file.filename, filename: file.filename).save(on: req).transform(to: ())
//            }.flatten(on: req).transform(to: .ok)
//        }
//    }
    
    func baseData(_ req: Request, urlDataToTrainingImage: UrlDataToTrainingImage) throws -> ResponseMessageFormSendingReq {
        let user = try req.requireAuthenticated(User.self)
        if urlDataToTrainingImage.url.count == 0 {
            return ResponseMessageFormSendingReq(identityName: user.username, status: 0, message: "Invalid input form, need add an array of URL or needed to send in JSON!")
        }

        let workPath = try req.make(DirectoryConfig.self).workDir
        let baseDataPath = workPath + mediaUploaded
        let userDataPath = try baseDataPath + "\(user.requireID())"
        var fileName = ""
        var alreadyGetData = false
        var inputUrlWork = 0
        var isHaveInvalidUrl = false

        for url in urlDataToTrainingImage.url {

            if !url.hasPrefix("http") { // can be deleted - 9
                continue
            }

//            let typeOfFileStartCharacter = url.index(url.endIndex, offsetBy: -4)
//            let typeOfFile = url[typeOfFileStartCharacter ..< url.endIndex]
//            if String(typeOfFile).hasPrefix(".") {
//                fileName = try "/\(user.requireID())-\(UUID().uuidString)\(String(typeOfFile))"
//            } else {
//                fileName = try "/\(user.requireID())-\(UUID().uuidString)\(suffixImage)"
//            }
            fileName = try "/\(user.requireID())-\(UUID().uuidString)\(suffixImage)"
            let fileInUserDataPath = userDataPath + fileName

            guard let imageURL = URL(string: url) else {
                return ResponseMessageFormSendingReq(identityName: user.username, status: 0, message: "Input '\(url)' is not type of URL!")
            }
            guard let imageData = try? Data(contentsOf: imageURL) else {
                continue
            }
            alreadyGetData = true
            inputUrlWork += 1

            if !FileManager().fileExists(atPath: userDataPath) {
                do {
                    try FileManager().createDirectory(atPath: userDataPath,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
                } catch {
                    throw Abort(.badRequest, reason: "\(error.localizedDescription)")
                }
                FileManager().createFile(atPath: fileInUserDataPath,
                                         contents: imageData,
                                         attributes: nil)
            } else {
                FileManager().createFile(atPath: fileInUserDataPath,
                                         contents: imageData,
                                         attributes: nil)
            }
        }

        if inputUrlWork != urlDataToTrainingImage.url.count {
            isHaveInvalidUrl = true
        }

        let _ = user.save(on: req)

        var responseSuccessMessage = ResponseMessageFormSendingReq(identityName: user.name, status: 0, message: "All input link is invalid!")
        if alreadyGetData == true {
            responseSuccessMessage = ResponseMessageFormSendingReq(identityName: user.username, status: 1, message: "Success!\(isHaveInvalidUrl ? " (" + "\(urlDataToTrainingImage.url.count - inputUrlWork)" + " invalid url!)" : "")")
        }
        return responseSuccessMessage
    }
    
    // original
//    func getCommentsOfPostID(_ req: Request)
//        throws -> Future<[Comment]> {
//            return try req
//                .parameters.next(Post.self)
//                .flatMap(to: [Comment].self) { post in
//                    try post
//                        .comments
//                        .query(on: req)
//                        .all()
//            }
//    }
    func getCommentsOfPostID(_ req: Request) throws -> Future<ResponseGetCommentOfPost> {
        return try req
            .parameters.next(Post.self)
            .flatMap(to: ResponseGetCommentOfPost.self) { post in
                try post
                    .comments
                    .query(on: req)
                    .all().map(to: ResponseGetCommentOfPost.self) { comments in
                        return ResponseGetCommentOfPost(code: 1000, message: "Get all comment of post successful!", data: comments)
                    }
            }
    }
    
    func getAllPosts(_ req: Request) throws -> Future<[Post]> {
        return Post
            .query(on: req)
            .all()
    }
    
    func getPosts(_ req: Request, searchData: SearchData) throws -> Future<[Post]> {
        let user = try req.requireAuthenticated(User.self)
        var idList = [UUID]()
        let range = Int(searchData.range ?? "50")!
        let searchTerm = ""
        return try user.friends.query(on: req).all().flatMap(to: [Post].self) { friends in
            for e in friends {
                idList.append(e.friendID)
            }
            if (searchData.dateType == "smt" && searchData.timeType == "smt") {
                return Post
                    .query(on: req)
                    .group(.and) { and in
                        and.filter(\.userID ~~ idList)
                        and.filter(\.date < searchTerm)
                        and.filter(\.time < searchTerm)
                    }.all()
            } else if (searchData.dateType == "smt" && searchData.timeType == "grt") {
                return Post
                    .query(on: req)
                    .group(.and) { and in
                        and.filter(\.userID ~~ idList)
                        and.filter(\.date < searchTerm)
                        and.filter(\.time > searchTerm)
                    }.all()
            } else if (searchData.dateType == "grt" && searchData.timeType == "smt") {
                return Post
                    .query(on: req)
                    .group(.and) { and in
                        and.filter(\.userID ~~ idList)
                        and.filter(\.date > searchTerm)
                        and.filter(\.time < searchTerm)
                    }.all()
            } else if (searchData.dateType == "grt" && searchData.timeType == "grt") {
                return Post
                    .query(on: req)
                    .group(.and) { and in
                        and.filter(\.userID ~~ idList)
                        and.filter(\.date > searchTerm)
                        and.filter(\.time > searchTerm)
                    }.all()
            }
            return Post
                .query(on: req)
                .group(.and) { and in
                    and.filter(\.userID ~~ idList)
                }.range(..<range).all()
        }
    }
    struct SearchData: Content {
        let dateType: String?
        let date: String?
        let timeType: String?
        let time: String?
        let range: String?
    }
    
    func getPostMedia(_ req: Request) throws -> Future<PostCreateData> {
        return try req
            .parameters
            .next(Post.self).map(to: PostCreateData.self) { post in
                
                let workPath = try req.make(DirectoryConfig.self).workDir
                let mediaUploadedPath = workPath + mediaUploaded
                let folderPath = mediaUploadedPath + "\(String(describing: post.id!))/"
                var fileURLs: [URL]?
                var annotationDatas = [File]()
                let fileManager = FileManager.default
                
                do {
                    fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: folderPath), includingPropertiesForKeys: nil)
                } catch {
                }
                for e in fileURLs! {
                    if !e.absoluteString.hasSuffix(".png") {
                        continue
                    }
                    let subE = e.absoluteString.reversed()
                    let fileName = String((String(subE[..<subE.firstIndex(of: "/")!])).reversed())
                    let annotationData = File(data: try Data(contentsOf: e), filename: fileName)
                    //                    annotationData += an
                    annotationDatas.append(annotationData)
                }
                
                let postCreateData = PostCreateData(date: post.date, time: post.time, content: post.content, typeMedia: "", video: "", image: "", file: annotationDatas, like: post.like)
                return postCreateData
            }
    }
    
    func putPostID(_ req: Request) throws -> Future<ResponseEditPost> {
        return try flatMap(
            to: ResponseEditPost.self,
            req.parameters.next(Post.self),
            req.content.decode(PostCreateData.self)) { post, updatedPost in
                post.date = updatedPost.date
                post.time = updatedPost.time
                post.content = updatedPost.content
                post.typeMedia = updatedPost.typeMedia
                post.video = updatedPost.video
                post.image = updatedPost.image
                let user = try req.requireAuthenticated(User.self)
                post.userID = try user.requireID()
            return post.save(on: req).map(to: ResponseEditPost.self) { editedPost in
                return ResponseEditPost(code: 1000, message: "Edit post successful!", data: editedPost)
            }
        }
    }
    
    func likedUpdate(_ req: Request) throws -> Future<ResponseLikeUpdate> {
        return try flatMap(
            to: ResponseLikeUpdate.self,
            req.parameters.next(Post.self),
            req.content.decode(LikedUpdate.self)) { post, updatedPost in
                post.like = updatedPost.like
            return post.save(on: req).map(to: ResponseLikeUpdate.self) { likedPost in
                return ResponseLikeUpdate(code: 1000, message: "Update like of post successful!", data: likedPost)
            }
        }
    }
    
    // original
//    func deletePostID(_ req: Request) throws -> Future<HTTPStatus> {
//        return try req
//            .parameters
//            .next(Post.self)
//            .delete(on: req)
//            .transform(to: .noContent)
//    }
    func deletePostID(_ req: Request) throws -> Future<ResponseDeletePost> {
        return try req
            .parameters
            .next(Post.self)
            .delete(on: req)
            .map(to: ResponseDeletePost.self) { post in
                return ResponseDeletePost(code: 1000, message: "Delete post successful!", data: post)
            }
    }
    
}

struct LikedUpdate: Content {
    let like: Int
}

//
struct UrlDataToTrainingImage: Content {
    var url: [String]
}

struct ResponseMessageFormSendingReq: Content {
    var identityName: String
    var status: Int
    var message: String
}
