import Vapor
import Fluent
import Authentication

struct PostsController: RouteCollection {
    
    let mediaUploaded = "MediaUploaded/"
    
    let errorDataOfUrlMessage = "Invalid URL!"
    
    let suffixImage = ".jpg"
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "posts")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.get(use: getAllPosts)
        tokenAuthGroup.post(PostCreateData.self, use: postPost)
        tokenAuthGroup.put(Post.parameter, use: putPostID)
        tokenAuthGroup.delete(Post.parameter, use: deletePostID)
    }
    
    func test(_ req: Request, data: Test) throws -> ResponseMessageFormSendingReq {
        
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + mediaUploaded
        let userDataPath = try mediaUploadedPath
        var fileName = ""
        fileName = try "test\(suffixImage)"
        let fileInUserDataPath = userDataPath + fileName
        FileManager().createFile(atPath: fileInUserDataPath,
                                 contents: data.file.data,
                                 attributes: nil)
        print(userDataPath)
        print(fileName)
        var responseSuccessMessage = ResponseMessageFormSendingReq(identityName: "user.name", status: 0, message: "All input link is invalid!")
        
            responseSuccessMessage = ResponseMessageFormSendingReq(identityName: "user.username", status: 1, message: "Success!")
        
        return responseSuccessMessage
        
    }
    
    func postPost(_ req: Request, data: PostCreateData) throws -> Future<Post> {
        let user = try req.requireAuthenticated(User.self)
        let post = try Post(
            dateUpload: data.dateUpload,
            content: data.content,
            typeMedia: data.typeMedia,
            video: data.video,
            image: data.image,
            userID: user.requireID())
        return post.save(on: req)
    }
    
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
    
    
    func getAllPosts(_ req: Request) throws -> Future<[Post]> {
        return Post
            .query(on: req)
            .all()
    }
    
    func putPostID(_ req: Request) throws -> Future<Post> {
        return try flatMap(
            to: Post.self,
            req.parameters.next(Post.self),
            req.content.decode(PostCreateData.self)) { post, updatedPost in
                post.dateUpload = updatedPost.dateUpload
                post.content = updatedPost.content
                post.typeMedia = updatedPost.typeMedia
                post.video = updatedPost.video
                post.image = updatedPost.image
                let user = try req.requireAuthenticated(User.self)
                post.userID = try user.requireID()
                return post.save(on: req)
        }
    }
    
    func deletePostID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Post.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

struct PostCreateData: Content {
    let dateUpload: String
    let content: String
    let typeMedia: String? // 0 is image 1 is video
    let video: String?
    let image: String?
    let file: File
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

struct Test: Content {
    var file: File
    var name: String
}
