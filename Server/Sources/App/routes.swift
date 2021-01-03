import Vapor
import Fluent
import FluentMySQL
import WebSocket

/// Register your application's routes here.
let sessionManager = TrackingSessionManager()

public func routes(_ router: Router) throws {
    
    //MARK: Construction link api.
    /// Get.
    // http://localhost:8080/api/acronyms/all
    // http://localhost:8080/api/acronyms/<id>
    
    /// Get with filter.
    // http://localhost:8080/api/acronyms/search/date?term=<variable>
    // http://localhost:8080/api/acronyms/search/time?term=<variable>
    // http://localhost:8080/api/acronyms/search/nameEvent?term=<variable>
    // http://localhost:8080/api/acronyms/sorted/date
    
    /// Post.
    // http://localhost:8080/api/acronyms
    
    /// Put.
    // http://localhost:8080/api/acronyms/<id>
    
    /// Delete.
    // http://localhost:8080/api/acronyms/<id>

    //MARK: Watchout chosing only one between AcronymsController and Controller cus it doing the same with Acronyms.
    // If has no creation of route in controller we use code below instead( create only in controller file or route file).
    /*
    //MARK: acronymsController
    let acronymsController = AcronymsController()
    //MARK: get
    router.get("api", "acronyms", "all", use: acronymsController.getAll)
    router.get("api", "acronyms", Acronym.parameter, use: acronymsController.getDataID)
    router.get("api", "acronyms", "search", "date", use: acronymsController.searchDate)
    router.get("api", "acronyms", "search", "time", use: acronymsController.searchTime)
    router.get("api", "acronyms", "search", "nameEvent", use: acronymsController.searchNameEvent)
    router.get("api", "acronyms", "search", "sorted", "date", use: acronymsController.searchSortedDate)
    
    //MARK: post
    router.post("api", "acronyms", use: acronymsController.postData)
    
    //MARK: put
    router.put("api", "acronyms", Acronym.parameter, use: acronymsController.putDataID)
    
    //MARK: delete
    router.delete("api", "acronyms", Acronym.parameter, use: acronymsController.deleteDataID)
    */
    
    //MARK: Controller.
    // We can use method below and transfer all router above to controller.
    let controller = AcronymsController()
    try router.register(collection: controller)
    
    let postsController = PostsController()
    try router.register(collection: postsController)
    
    let friendsController = FriendsController()
    try router.register(collection: friendsController)
    
    let commentsController = CommentsController()
    try router.register(collection: commentsController)
    
    let annotationsController = AnnotationsController()
    try router.register(collection: annotationsController)
    
    //MARK: UsersController.
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    //MARK: CategoryController.
    let categoriesController = CategoriesController()
    try router.register(collection: categoriesController)
    
    //MARK: WebsiteController.
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
    
    //MARK: MessageController.
    let roomsController = RoomsController()
    try router.register(collection: roomsController)
    //MARK: MessageController.
    let messagesController = MessagesController()
    try router.register(collection: messagesController)
    
    // MARK: - Store
//    let webController = WebController()
//    try router.register(collection: webController)

    // MARK: WS
    // MARK: Status Checks
    
    router.get("status") { _ in "ok \(Date())" }
    
    router.get("word-test") { request in
        return wordKey(with: request)
    }
    
    router.get("file-stream", String.parameter) { req -> EventLoopFuture<Response> in
        let file = try req.parameters.next(String.self)
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + "Public/\(file)".replacingOccurrences(of: "*", with: "/")
//        let stream = try req.fileio().chunkedStream(file: mediaUploadedPath)
        let stream = try req.fileio().chunkedStream(file: mediaUploadedPath, chunkSize: 500)
        var res = HTTPResponse(status: .ok, body: stream)
        if file.hasSuffix("mp4") {
            res.contentType = .mp4
        } else if file.hasSuffix("png") {
            res.contentType = .png
        } else if file.hasSuffix("jpg") || file.hasSuffix("jpeg") {
            res.contentType = .jpeg
        }
        res.headers.add(name: "Accept-Ranges", value: "bytes")
//            = "Accept-Ranges"
        res.headers.add(name: "Cache-Control", value: "max-age=604800, no-transform")
//        res.headers.add(name: "Content-Length", value: "10000")
//        return res
        
        return try req.streamFile(at: mediaUploadedPath)
    }
    
    // MARK: Poster Routes
    
//    router.post("create", use: sessionManager.createTrackingSession)
    router.post("create", String.parameter) { req -> ResponseCreateWS in
        let userID = try req.parameters.next(String.self)
        return sessionManager.createTrackingSessionForIndivisualUser(for: userID)
    }
    
    router.post("createChatWS") { req -> Future<ResponseCreateWS> in
        return try CreatedSocketForm.decode(from: req).flatMap(to: ResponseCreateWS.self) { data in
            let sum = data.from > data.to ? "\(data.from)\(data.to)" : "\(data.to)\(data.from)"
            print(sum)
            var checkReturn = false
            return Room.query(on: req).filter(\.sumUserID == sum).first().flatMap(to: ResponseCreateWS.self) { roomE in
                if roomE != nil && roomE!.id! % 1 == 0 {
                    checkReturn = true
                } else {
                    
                }
                print(checkReturn)
//                return ResponseCreateWS(code: 1000, message: "", data: InFoWS(id: "nkn", roomID: 0))
                if checkReturn {
                    return Room.query(on: req).filter(\.sumUserID == sum).first().map(to: ResponseCreateWS.self) { roomE in
                        return ResponseCreateWS(code: 1000, message: "Session did exist!", data: InFoWS(id: sum, roomID: (roomE?.id!)!))
                    }
                }
                let room = Room(test: "", sumUserID: sum, useridText1: data.from, useridText2: data.to, userID1: UUID(data.from)!, userID2: UUID(data.to)!)
                return room.save(on: req).map(to: ResponseCreateWS.self) { room in
                    return sessionManager.createTrackingSession(for: data, roomID: room.id!, userID: data.from)
                }
            }
        }
    }
    
    router.post("close", TrackingSession.parameter) { req -> HTTPStatus in
        let session = try req.parameters.next(TrackingSession.self)
        sessionManager.close(session)
        return .ok
    }
    
    router.post("update", TrackingSession.parameter) { req -> Future<HTTPStatus> in
        let session = try req.parameters.next(TrackingSession.self)
        return try Message.decode(from: req).map(to: HTTPStatus.self) { message in
//            sessionManager.update("from 1", for: session)
            let _ = message.save(on: req)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(message)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            sessionManager.update(json!, for: session, to: message.to)
            print(json)
            return .ok
        }
    }
    
    let searchController = SearchController()
    try router.register(collection: searchController)
    
    let settingController = SettingController()
    try router.register(collection: settingController)
    /*
    //MARK: Get.
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("hello", "vapor") { req -> String in
        return "Hello Vapor!"
    }
    
    router.get("hello", String.parameter) { req -> String in
        let name = try req.parameters.next(String.self)
        return "Hello, \(name)!"
    }

    // http://localhost:8080/api/acronyms/all
//    router.get("api", "acronyms", "all") { req -> Future<[Acronym]> in
//        return Acronym.query(on: req).all()
//    }
    
    // http://localhost:8080/api/acronyms/<id>
//    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
//        return try req.parameters.next(Acronym.self)
//    }
    
    //MARK: Get with filter.
    // http://localhost:8080/api/acronyms/search/date?term=<variable>
//    router.get("api", "acronyms", "search", "date") { req -> Future<[Acronym]> in
//        guard let searchTerm = req.query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return Acronym.query(on: req).filter(\.date == searchTerm).all()
//
//        return Acronym.query(on: req).group(.or) { or in
//            or.filter(\.nameEvent == searchTerm)
//            or.filter(\.date == searchTerm)
//            or.filter(\.time == searchTerm)
//            or.filter(\.link == searchTerm)
//        }.all()
//
//        return Acronym.query(on: req).group(.or) { or in
//            or.filter(\.nameEvent != searchTerm)
//            or.filter(\.date != searchTerm)
//            or.filter(\.time != searchTerm)
//            or.filter(\.link != searchTerm)
//        }.all()
//    }
    
    // http://localhost:8080/api/acronyms/search/time?term=<variable>
//    router.get("api", "acronyms", "search", "time") { req -> Future<[Acronym]> in
//        guard let searchTerm = req.query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return Acronym.query(on: req).filter(\.time == searchTerm).all()
//    }
    
    // http://localhost:8080/api/acronyms/search/nameEvent?term=<variable>
//    router.get("api", "acronyms", "search", "nameEvent") { req -> Future<[Acronym]> in
//        guard let searchTerm = req.query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return Acronym.query(on: req).filter(\.nameEvent == searchTerm).all()
//    }
    

    
    // http://localhost:8080/api/acronyms/first
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym.query(on: req).first().unwrap(or: Abort(.notFound))
    }
    
    // http://localhost:8080/api/acronyms/sorted/date
//    router.get("api", "acronyms", "sorted", "date") { req -> Future<[Acronym]> in
//        return Acronym.query(on: req).sort(\.date, .descending).all()
//    }
    
    //MARK: Post.
    router.post(InfoData.self, at: "info") { req, data -> String in
        return "Hello \(data.name)!"
    }
    
    router.post(InfoData.self, at: "info") {req, data -> InfoResPonse in
        return InfoResPonse(request: data)
    }
    
    // http://localhost:8080/api/acronyms
//    router.post("api", "acronyms") { req -> Future<Acronym> in
//        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
//            return acronym.save(on: req)
//        }
//    }
    
    //MARK: Put.
    // http://localhost:8080/api/acronyms/<id>
//    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
//        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updatedAcronym in
//            acronym.nameEvent = updatedAcronym.nameEvent
//            acronym.date = updatedAcronym.date
//            acronym.time = updatedAcronym.time
//            acronym.link = updatedAcronym.link
//            return acronym.save(on: req)
//        }
//    }
    
    //MARK: Delete.
    // http://localhost:8080/api/acronyms/<id>
//    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
//        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: .noContent)
//    }
    
    // Example of configuring a controller
    //    let todoController = TodoController()
    //    router.get("todos", use: todoController.index)
    //    router.post("todos", use: todoController.create)
    //    router.delete("todos", Todo.parameter, use: todoController.delete)
    */

}

/*
 struct InfoData: Content {
 let name: String
 }
 
 struct InfoResPonse: Content {
 let request: InfoData
 }
 */

struct CreatedSocketForm: Content {
    let from: String
    let to: String
}


/// Serves static files from a public directory.
///
///     middlewareConfig = MiddlewareConfig()
///     middlewareConfig.use(FileMiddleware.self)
///     services.register(middlewareConfig)
///
/// `FileMiddleware` will default to `DirectoryConfig`'s working directory with `"/Public"` appended.

/// A custom class that replaces FileMiddleware temporarily until the issue below is fixed:
/// https://github.com/vapor/vapor/issues/1762
public final class StreamableFileMiddleware: Middleware, ServiceType {
  /// See `ServiceType`.
  public static func makeService(for container: Container) throws -> StreamableFileMiddleware {
    return try .init(publicDirectory: container.make(DirectoryConfig.self).workDir + "Public/")
  }
  
  /// The public directory.
  /// - note: Must end with a slash.
  private let publicDirectory: String
  
  /// Creates a new `FileMiddleware`.
  public init(publicDirectory: String) {
    self.publicDirectory = publicDirectory.hasSuffix("/") ? publicDirectory : publicDirectory + "/"
  }
  
  /// See `Middleware`.
  public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
    // make a copy of the path
    var path = req.http.url.path
    
    // path must be relative.
    while path.hasPrefix("/") {
      path = String(path.dropFirst())
    }
    
    // protect against relative paths
    guard !path.contains("../") else {
      throw Abort(.forbidden)
    }
    
    // create absolute file path
    let filePath = publicDirectory + path
    

    if let response = rangeHeaderResponse(in: req, filePath: filePath) {
      return response
    }
    
    // check if file exists and is not a directory
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
      return try next.respond(to: req)
    }
    
    // stream the file
    return try req.streamFile(at: filePath)
  }
  
  /// This is a hack to add support for Range Headers in FileMiddleware
  /// https://github.com/vapor/vapor/issues/1762
  ///
  /// Refactored from code written by Joe Kramer
  /// https://iosdevelopers.slack.com/archives/C0G0MMJ69/p1549997917004000
  ///
  /// - Parameters:
  ///   - req: Reuest
  ///   - filePath: The string of the file location being processed
  /// - Returns: A future for a Response or nil
  func rangeHeaderResponse(in req: Request, filePath: String) -> EventLoopFuture<Response>? {
    guard
      let rangeHeader = req.http.headers.firstValue(name: HTTPHeaderName.range),
      let data = NSData(contentsOfFile: filePath),
      rangeHeader.starts(with: "bytes=") else {
        return nil
    }
    
    let split = String(rangeHeader.dropFirst(6)).split(separator: "-")
    
    guard split.count == 2, let start = Int(split[0]), let end = Int(split[1]) else {
      fatalError("Range header formatting is unexpected")
    }
    
    let length = end - start + 1
    if length > 0 {
      let retValue = data.subdata(with: NSRange(location: start, length: length))
      let res = req.response()
      res.http.status = .partialContent
      res.http.headers.add(name: HTTPHeaderName.contentLength, value: "\(length)")
      res.http.headers.add(name: HTTPHeaderName.contentRange, value: "bytes \(start)-\(end)/\(data.length)")
      res.http.headers.add(name: HTTPHeaderName.acceptRanges, value: "bytes")
      res.http.body = HTTPBody(data: retValue)
      let future = req.eventLoop.newSucceededFuture(result: res)
      return future
    }
    
    return nil
  }
}
