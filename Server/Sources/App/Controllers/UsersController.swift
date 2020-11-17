import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
//        usersRoute.post(User.self, use: createUser)
        usersRoute.get(use: getAllUsers)
        usersRoute.get(User.parameter, use: getUserID)
        usersRoute.delete(User.parameter, use: deleteUserID)
        
        //MARK: Get acronyms.
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsOfUserID)
        
        /// Create a protected route group using HTTP basic authentication, as you did for creating an acronym. This doesn’t use GuardAuthenticationMiddleware since requireAuthenticated(_:) throws the correct error if a user isn’t authenticated.
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        
        
        /// Using tokenAuthMiddleware and guardAuthMiddleware ensures only authenticated users can create other users. This prevents anyone from creating a user to send requests to the routes you’ve just protected.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(User.self, use: createUser)
        
        
        
    }
    
    //MARK: None protect password hashes and never return them in responses.
    // http://localhost:8080/api/users
//    func createUser(_ req: Request, user: User) throws -> Future<User> {
//        user.password = try BCrypt.hash(user.password)
//        return user
//            .save(on: req)
//    }

    // http://localhost:8080/api/users
//    func getAllUsers(_ req: Request) throws -> Future<[User]> {
//        return User
//            .query(on: req)
//            .all()
//    }
    
    // http://localhost:8080/api/users/<userID>
//    func getUserID(_ req: Request) throws -> Future<User> {
//        return try req
//            .parameters
//            .next(User.self)
//    }

    //MARK: Protect password hashes and never return them in responses.
    // http://localhost:8080/api/users
    func createUser(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user
            .save(on: req)
            .convertToPublic()
    }
    
    // http://localhost:8080/api/users
    func getAllUsers(_ req: Request) throws -> Future<[User.Public]> {
        return User
            .query(on: req)
            .decode(data: User.Public.self)
            .all()
    }
    
    // http://localhost:8080/api/users/<userID>
    func getUserID(_ req: Request) throws -> Future<User.Public> {
        return try req
            .parameters
            .next(User.self)
            .convertToPublic()
    }
    
    // http://localhost:8080/api/users
    func deleteUserID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(User.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
    //MARK: Get acronyms.
    // http://localhost:8080/api/users/<userID>/acronyms
    func getAcronymsOfUserID(_ req: Request)
        throws -> Future<[Acronym]> {
            return try req
                .parameters.next(User.self)
                .flatMap(to: [Acronym].self) { user in
                    try user
                        .acronyms
                        .query(on: req)
                        .all()
            }
    }
    
    // MARK: Login.
    // http://localhost:8080/api/users/login
    // 1
    func loginHandler(_ req: Request) throws -> Future<Token> {
        // 2
        let user = try req.requireAuthenticated(User.self)
        // 3
        let token = try Token.generate(for: user)
        // 4
        return token.save(on: req)
    }/*
     1. Define a route handler for logging a user in.
     2. Get the authenticated user from the request. You’ll protect this route with the HTTP basic authentication middleware. This saves the user’s identity in the request’s authentication cache, allowing you to retrieve the user object later. requireAuthenticated(_:) throws an authentication error if there’s no authenticated user.
     3. Create a token for the user.
     4. Save and return the token.
     */
}
