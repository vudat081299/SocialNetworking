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
    
    // MARK: Poster Routes
    
//    router.post("create", use: sessionManager.createTrackingSession)
    router.post("create", String.parameter) { req -> ResponseCreateWS in
        let userID = try req.parameters.next(String.self)
        return sessionManager.createTrackingSessionForIndivisualUser(for: userID)
    }
    
    router.post("createChatWS") { req -> Future<ResponseCreateWS> in
        return try CreatedSocketForm.decode(from: req).map(to: ResponseCreateWS.self) { data in
            let sum = data.from > data.to ? "\(data.from)\(data.to)" : "\(data.to)\(data.from)"
            let room = Room(test: "", sumUserID: sum, useridText1: data.from, useridText2: data.to, userID1: UUID(data.from)!, userID2: UUID(data.to)!)
            let _ = room.save(on: req)
            return sessionManager.createTrackingSession(for: data)
        }
    }
    
    router.post("close", TrackingSession.parameter) { req -> HTTPStatus in
        let session = try req.parameters.next(TrackingSession.self)
        sessionManager.close(session)
        return .ok
    }
    
    router.post("update", TrackingSession.parameter) { req -> Future<HTTPStatus> in
        let session = try req.parameters.next(TrackingSession.self)
        return try Message.decode(from: req).map(to: HTTPStatus.self) { location in
            sessionManager.update("from 1", for: session)
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
