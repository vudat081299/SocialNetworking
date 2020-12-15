import Vapor
import Crypto

public func sockets(_ websockets: NIOWebSocketServer) {
    // Status
    
//    websockets.get("echo-test") { ws, req in
//        print("ws connnected")
//        ws.onText { ws, text in
//            print("ws received: \(text)")
//            ws.send("echo - \(text)")
//        }
//    }
    
    // Listener
//    websockets.get("listen", TrackingSession.parameter) { ws, req in
//        let session = try req.parameters.next(TrackingSession.self)
//        guard sessionManager.sessions[session] != nil else {
//            ws.close()
//            return
//        }
//        sessionManager.add(listener: ws, to: session)
//    }
    
    // Status
    
    websockets.get("echo-test") { ws, req in
        print("ws connnected")
        ws.onText { ws, text in
            print("ws received: \(text)")
            ws.send("echo - \(text)")
        }
    }
    
    // Listener
    
    websockets.get("listen", TrackingSession.parameter) { ws, req in
        let session = try req.parameters.next(TrackingSession.self)
        guard sessionManager.sessions[session] != nil else {
            ws.close()
            return
        }
        sessionManager.add(listener: ws, to: session)
    }
}

struct UsersController: RouteCollection {
    
    let profilePictureFolder = "ProfilePictures/"
    
    let suffixImage = ".png"
    
    func boot(router: Router) throws {
        
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(PostCreatedUser.self, use: createUser)
        usersRoute.get(use: getAllUsers)
        usersRoute.get(User.parameter, use: getUserID)
        usersRoute.delete(User.parameter, use: deleteUserID)
        
        //MARK: Get acronyms.
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsOfUserID)
        usersRoute.get(User.parameter, "posts", use: getPostsOfUserID)
        usersRoute.get(User.parameter, "friends", use: getFriendsOfUserID)
        usersRoute.put(User.parameter, use: updateUser)
        
        /// Create a protected route group using HTTP basic authentication, as you did for creating an acronym. This doesn’t use GuardAuthenticationMiddleware since requireAuthenticated(_:) throws the correct error if a user isn’t authenticated.
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        
        
        /// Using tokenAuthMiddleware and guardAuthMiddleware ensures only authenticated users can create other users. This prevents anyone from creating a user to send requests to the routes you’ve just protected.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        // MARK: - Put
        // Add avatar
        //        tokenAuthGroup.post(User.self, use: createUser)
        //        tokenAuthGroup.put(User.self, use: updateUser)
        
        //        let loop = EmbeddedEventLoop()
        //        let promise = loop.newPromise(String.self)
        //        let futureString: Future<String> = promise.futureResult
        //        let futureInt = futureString.map(to: Int.self) { string in
        //          print("string: \(string)")
        //          return Int(string) ?? 0
        //        }
        //        promise.succeed(result: "16")
        //        print(try futureInt.wait())
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
    func createUser(_ req: Request, data: PostCreatedUser) throws -> Future<User.Public> {
        //        user.password = try BCrypt.hash(user.password)
        //        return user
        //            .save(on: req)
        //            .convertToPublic()
        let user = User(
            name: data.name,
            username: data.username,
            password: try BCrypt.hash(data.password),
            email: data.email,
            phonenumber: data.phonenumber,
            idDevice: data.idDevice)
        
        let workPath = try req.make(DirectoryConfig.self).workDir
        let mediaUploadedPath = workPath + profilePictureFolder
        let folderPath = mediaUploadedPath + ""
        return user
            .save(on: req)
            .map { user2nd in
                if data.file?.data != nil {
                    let fileName = "\(String(describing: user2nd.id!))\(self.suffixImage)"
                    let filePath = folderPath + fileName
                    FileManager().createFile(atPath: filePath,
                                             contents: data.file?.data,
                                             attributes: nil)
                    print("Saving profile picture at: \(filePath)")
                    user2nd.profilePicture = fileName
                }
                return user2nd
            }
            .update(on: req)
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
    func getPostsOfUserID(_ req: Request)
        throws -> Future<[Post]> {
            return try req
                .parameters.next(User.self)
                .flatMap(to: [Post].self) { user in
                    try user
                        .posts
                        .query(on: req)
                        .all()
            }
    }
    func getFriendsOfUserID(_ req: Request)
        throws -> Future<[Friend]> {
            return try req
                .parameters.next(User.self)
                .flatMap(to: [Friend].self) { user in
                    try user
                        .friends
                        .query(on: req)
                        .all()
            }
    }
    
    func updateUser(_ req: Request) throws -> Future<User.Public> {
        return try flatMap(
            to: User.Public.self,
            req.parameters.next(User.self),
            req.content.decode(PostCreatedUser.self)) { user, updatedUser in
                user.name = updatedUser.name
                user.username = updatedUser.username
                user.password = try BCrypt.hash(updatedUser.password)
                user.email = updatedUser.email
                user.phonenumber = updatedUser.phonenumber
                user.idDevice = updatedUser.idDevice
                
                // save profile picture
                if updatedUser.file?.data != nil {
                    let workPath = try req.make(DirectoryConfig.self).workDir
                    let mediaUploadedPath = workPath + self.profilePictureFolder
                    let folderPath = mediaUploadedPath + ""
                    let fileName = "\(String(describing: user.id!))\(self.suffixImage)"
                    let filePath = folderPath + fileName
                    FileManager().createFile(atPath: filePath,
                                             contents: updatedUser.file?.data,
                                             attributes: nil)
                    user.profilePicture = fileName
                }
                
                return user.save(on: req).convertToPublic()
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

struct PostCreatedUser: Content {
    let name: String
    let username: String
    let password: String
    let file: File?
    let email: String?
    let phonenumber: String?
    let idDevice: String?
}
