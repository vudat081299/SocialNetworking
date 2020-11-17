import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {

    /// We can add func() into boot(router:) or take it out.
    /// If has no creation of route in Route file we follow code below instead( create only in Controller file or Route file).
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        //MARK: Authentication.
        // 1
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//        // 2
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        // 3
//        let protected = acronymsRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
//        // 4
//        protected.post(Acronym.self, use: postAcronym)
        /*
         1. Instantiate a basic authentication middleware which uses BCryptDigest to verify passwords. Since User conforms to BasicAuthenticatable, this is available as a static function on the model.
         2. Create an instance of GuardAuthenticationMiddleware which ensures that requests contain valid authorization.
         3. Create a middleware group which uses basicAuthMiddleware and guardAuthMiddleware.
         4. Connect the “create acronym” path to createHandler(_:acronym:) through this middleware group.
         */
        
        // 1
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        // 2
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        // 3
        tokenAuthGroup.post(AcronymCreateData.self, use: postAcronym)
        /*
         1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
         2. Create a route group using tokenAuthMiddleware and guardAuthMiddleware to protect the route for creating an acronym with token authentication.
         3. Connect the “create acronym” path to createHandler(_:data:) through this middleware group using the new AcronymCreateData.
         */
        
//        acronymsRoutes.post(use: createHandler)
//        acronymsRoutes.post(Acronym.self, use: postAcronym)
                
        tokenAuthGroup.get(use: getAllAcronyms)
        tokenAuthGroup.get(Acronym.parameter, use: getAcronymID)
        tokenAuthGroup.get("search", use: searchAcronyms)
//        acronymsRoutes.get("first", use: getFirstHandler)
        tokenAuthGroup.get("sorted", use: sortedAcronyms)
        tokenAuthGroup.put(Acronym.parameter, use: putAcronymID)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteAcronymID)
        
        //MARK: Get user.
        tokenAuthGroup.get(Acronym.parameter, "user", use: getUserOfAcronym)
        
        //MARK: Categories.
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use: addSiblingRelationshipBetweenAcronymAndCategory)
        tokenAuthGroup.get(Acronym.parameter, "categories", use: getCategoriesOfAcronym)
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeSiblingRelationshipBetweenAcronymAndCategory)
        
        
    }
        
    
//        func createHandler(_ req: Request) throws -> Future<Acronym> {
//            return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
//                return acronym.save(on: req)
//            }
//        }
    
    
    //MARK: Post.
//    func postAcronym(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
//        return acronym
//            .save(on: req)
//    }
    
    // 1
    func postAcronym(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        // 2
        let user = try req.requireAuthenticated(User.self)
        // 3
        let acronym = try Acronym(
            nameEvent: data.nameEvent,
            date: data.date,
            time: data.time,
            link: data.link,
            userID: user.requireID())
        // 4
        return acronym.save(on: req)
    }/*
     1. Define a route handler that accepts AcronymCreateData as the request body.
     2. Get the authenticated user from the request.
     3. Create a new Acronym using the data from the request and the authenticated user.
     4. Save and return the acronym.
     */
    
    //MARK: Get.
    func getAllAcronyms(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym
            .query(on: req)
            .all()
    }
    
    
    func getAcronymID(_ req: Request) throws -> Future<Acronym> {
        return try req
            .parameters
            .next(Acronym.self)
    }

    
    //MARK: Put.
//    func putAcronymID(_ req: Request) throws -> Future<Acronym> {
//        return try flatMap(
//            to: Acronym.self,
//            req.parameters.next(Acronym.self),
//            req.content.decode(Acronym.self)) { acronym, updatedAcronym in
//            acronym.nameEvent = updatedAcronym.nameEvent
//            acronym.date = updatedAcronym.date
//            acronym.time = updatedAcronym.time
//            acronym.link = updatedAcronym.link
//            acronym.userID = updatedAcronym.userID
//            return acronym.save(on: req)
//        }
//    }
    
    func putAcronymID(_ req: Request) throws -> Future<Acronym> {
        // 1
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(AcronymCreateData.self)) { acronym, updatedAcronym in
                acronym.nameEvent = updatedAcronym.nameEvent
                acronym.date = updatedAcronym.date
                acronym.time = updatedAcronym.time
                acronym.link = updatedAcronym.link
                // 2
                let user = try req.requireAuthenticated(User.self)
                acronym.userID = try user.requireID()
                return acronym.save(on: req)
        }
    }/*
     1. Decode the request’s data to AcronymCreateData since request no longer contains the user’s ID in the post data.
     2. Get the authenticated user from the request and use that to update the acronym.
     */
    
    //MARK: Delete.
    func deleteAcronymID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
    
    //MARK: Search.
    func searchAcronyms(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.nameEvent == searchTerm)
            or.filter(\.date == searchTerm)
            or.filter(\.time == searchTerm)
            or.filter(\.link == searchTerm)
        }.all()
    }
        
    
//    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
//        return Acronym.query(on: req)
//            .first()
//            .unwrap(or: Abort(.notFound))
//    }
    
    
    //MARK: Sort.
    func sortedAcronyms(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym
            .query(on: req)
            .sort(\.date, .ascending)
            .all()
    }
    
    
    //MARK: Get users.
    // http://localhost:8080/api/acronyms/<acronymID>/user
//    func getUserOfAcronym(_ req: Request) throws -> Future<User> {
//        return try req
//            .parameters
//            .next(Acronym.self)
//            .flatMap(to: User.self) { acronym in
//                acronym
//                    .user
//                    .get(on: req)
//        }
//    }
    
    
    // http://localhost:8080/api/acronyms/<acronymID>/user
    func getUserOfAcronym(_ req: Request) throws -> Future<User.Public> {
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: User.Public.self) { acronym in
                acronym
                    .user
                    .get(on: req)
                    .convertToPublic()
        }
    }
    
    
    //MARK: Categories.
    // http://localhost:8080/api/acronyms/<acronymID>/categories
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
    
    
    // http://localhost:8080/api/acronyms/<acronymID>/categories/<categoryID>
    // 1
    func addSiblingRelationshipBetweenAcronymAndCategory(_ req: Request) throws -> Future<HTTPStatus> {
        // 2
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)) { acronym, category in
                // 3
                return acronym
                    .categories
                    .attach(category, on: req)
                    .transform(to: .created)
        }
    }/*
     1. Define a new route handler, addCategoriesHandler(_:), that returns a Future<HTTPStatus>.
     2. Use flatMap(to:_:_:) to extract both the acronym and category from the request’s parameters.
     3. Use attach(_:on:) to set up the relationship between acronym and category. This creates a pivot model and saves it in the database. Transform the result into a 201 Created response.
     */
    
    
    // http://localhost:8080/api/acronyms/<acronymID>/categories/<categoryID>
    // 1
    func removeSiblingRelationshipBetweenAcronymAndCategory(_ req: Request) throws -> Future<HTTPStatus> {
        // 2
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)) { acronym, category in
                // 3
                return acronym
                    .categories
                    .detach(category, on: req)
                    .transform(to: .noContent)
        }
    }/*
     1. Define a new route handler, removeCategoriesHandler(_:), that returns a Future<HTTPStatus>.
     2. Use flatMap(to:_:_:) to extract both the acronym and category from the request’s parameters.
     3. Use detach(_:on:) to remove the relationship between acronym and category. This finds the pivot model in the database and deletes it. Transform the result into a 204 No Content response.
     */
    
    
    
}

/// This defines the request data that a user now has to send to create an acronym.
struct AcronymCreateData: Content {
    let nameEvent: String
    let date: String
    let time: String
    let link: String
}
