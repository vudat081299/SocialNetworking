import Vapor
import Crypto
import Fluent
import Authentication
import Leaf

struct UsersController: RouteCollection {
    
    let profilePictureFolder = "ProfilePictures/"
    let suffixImage = ".png"
    
    func boot(router: Router) throws {
        
        let usersRoute = router.grouped("api", "users")
        
        usersRoute.get("a", use: a)
        /// Create a protected route group using HTTP basic authentication, as you did for creating an acronym. This doesn’t use GuardAuthenticationMiddleware since requireAuthenticated(_:) throws the correct error if a user isn’t authenticated.
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        
        /// Using tokenAuthMiddleware and guardAuthMiddleware ensures only authenticated users can create other users. This prevents anyone from creating a user to send requests to the routes you’ve just protected.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
//        tokenAuthGroup.post("rooms", use: getRoomsOfUserID)
        
        usersRoute.post(PostCreatedUser.self, use: createUser)
        tokenAuthGroup.get(use: getAllUsers)
        tokenAuthGroup.get(User.parameter, use: getUserID)
        tokenAuthGroup.delete(User.parameter, use: deleteUserID)
        
        //MARK: Get acronyms.
        tokenAuthGroup.get(User.parameter, "acronyms", use: getAcronymsOfUserID)
        tokenAuthGroup.get(User.parameter, "posts", use: getPostsOfUserID)
        tokenAuthGroup.get(User.parameter, "friends", use: getFriendsOfUserID)
        
//        http://192.168.1.65:8080/api/users?rooms=377FE63D-D35E-4DA6-A0C5-AFE5A58CC8B0
        tokenAuthGroup.get("rooms", use: getRoomsOfUserID) // xss
        
        tokenAuthGroup.put(User.parameter, use: updateUser)
        tokenAuthGroup.put(User.parameter, "password", use: updateUserPassword)
        tokenAuthGroup.get("search_users", use: searchUsers)
        
        
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
    
    func a(_ req: Request) throws -> Future<[User.Public]> {
        
        return User.query(on: req).group(.or) { or in
            or.filter(\.name ~~ ["", "aa"])
        }.decode(data: User.Public.self)
        .all()
    }
    
    func getFriendsList(_ req: Request) throws -> Future<ReponseGetFriendsList> {
            let user = try req.requireAuthenticated(User.self)
            var idList = [UUID]()
//            var userList = [User.Public]()
            return try user.friends.query(on: req).all().flatMap(to: ReponseGetFriendsList.self) { friends in
                for e in friends {
                    idList.append(e.friendID)
                }
                return User.query(on: req)
                    .decode(data: User.Public.self)
                    .group(.or) { or in
                    or.filter(\.id ~~ idList)
                    }.all().map(to: ReponseGetFriendsList.self) { users in
                        return ReponseGetFriendsList(code: 1000, message: "Get all friend of user successful!", data: users)
                    }
                
            }
    }
    
    
//    func getRoomsOfUserID(_ req: Request) throws -> Future<[Room]> {
//        guard let searchTerm = req.query[String.self, at: "term"] else {
//            throw Abort(.badRequest)
//        }
//        return Room.query(on: req).group(.or) { or in
//            or.filter(\.)
//        }.all()
//    }
    
    func searchUsers(_ req: Request) throws -> Future<ResponseSearchUsers> {
        guard let searchTerm = req.query[String.self, at: "search_users"] else {
            throw Abort(.badRequest)
        }
        return User.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.username == searchTerm)
            or.filter(\.email == searchTerm)
            or.filter(\.phonenumber == searchTerm)
        }.decode(data: User.Public.self)
        .all()
        .map(to: ResponseSearchUsers.self) { users in
            return ResponseSearchUsers(code: 1000, message: "Found \(user.self)", data: users)
        }
    }
    
    func getRoomsOfUserID(_ req: Request) throws -> Future<ResponseGetRoomsOfUserID> {
        guard let searchTerm = req.query[String.self, at: "userid"] else {
            throw Abort(.badRequest)
        }
        return Room.query(on: req).group(.or) { or in
            or.filter(\.useridText1 == searchTerm)
            or.filter(\.useridText2 == searchTerm)
        }.all()
        .map(to: ResponseGetRoomsOfUserID.self) { rooms in
            return ResponseGetRoomsOfUserID(code: 1000, message: "Get all rooms chat of user have id: \(searchTerm) successful!", data: rooms)
        }
    }

//        return try req
//            .parameters.next(User.self)
//            .flatMap(to: [Room].self) { user in
//                let atRoom1 = try user
//                    .room1
//                    .query(on: req)
//                    .all()
//                let atRoom2 = try user
//                    .room2
//                    .query(on: req)
//                    .all()
//                let mergeArray = [atRoom1, atRoom2]
//                flatMap
//                flatMap(atRoom1, atRoom2) { room1, room2 in
////                    let a = room1.append
//                }
////                    return (mergeArray.flatMap { $0 })
//
//            }
//    }
    
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
    func createUser(_ req: Request, data: PostCreatedUser) throws -> Future<ResponseCreateUser> {
//        do {
//            try data.validate()
//        }
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
                                             contents: data.file!.data,
                                             attributes: nil)
                    print("Saving profile picture at: \(filePath)")
                    user2nd.profilePicture = fileName
                }
                return user2nd
            }
            .update(on: req)
            .convertToPublic()
            .map(to: ResponseCreateUser.self) { user in
                
                // save profile picture
                if data.file?.data != nil {
                    let workPath = try req.make(DirectoryConfig.self).workDir
                    let mediaUploadedPath = workPath + self.profilePictureFolder
                    let folderPath = mediaUploadedPath + ""
                    let fileName = "\(String(describing: user.id!))\(self.suffixImage)"
                    let filePath = folderPath + fileName
                    FileManager().createFile(atPath: filePath,
                                             contents: data.file?.data,
                                             attributes: nil)
                    user.profilePicture = fileName
                }
                
                return ResponseCreateUser(code: 1000, message: "Create user successful!", data: user)
            }
    }
    
    // http://localhost:8080/api/users
    func getAllUsers(_ req: Request) throws -> Future<ResponseGetAllUser> {
        return User
            .query(on: req)
            .decode(data: User.Public.self)
            .all()
            .map(to: ResponseGetAllUser.self) { users in
                return ResponseGetAllUser(code: 1000, message: "Successful!", data: users)
            }
    }
    
    // http://localhost:8080/api/users/<userID>
    func getUserID(_ req: Request) throws -> Future<ResponseGetUserByID> {
        
        let authUser = try req.requireAuthenticated(User.self)
        return try req
            .parameters
            .next(User.self)
            .convertToPublic()
            .map(to: ResponseGetUserByID.self) { user in
                let workPath = try req.make(DirectoryConfig.self).workDir
                let mediaUploadedPath = workPath + profilePictureFolder
//                let folderPath = mediaUploadedPath + "\(String(describing: post.id!))/"
                
                let fileName = "\(String(describing: user.id!))\(suffixImage)"
                let filePath = mediaUploadedPath + fileName
                let file = File(data: try Data(contentsOf: URL(fileURLWithPath: filePath)), filename: String(describing: authUser.id!))
                return ResponseGetUserByID(code: 1000, message: "Get user's infomation by id successful!", data: DataOfUser(avar: file, data: user))
            }
    }
    
    // http://localhost:8080/api/users
//    func deleteUserID(_ req: Request) throws -> Future<HTTPStatus> {
//        return try req
//            .parameters
//            .next(User.self)
//            .delete(on: req)
//            .transform(to: .noContent)
//    }
    func deleteUserID(_ req: Request) throws -> Future<ResponseDeleteUserByID> {
        return try req
            .parameters
            .next(User.self)
            .delete(on: req)
            .map(to: ResponseDeleteUserByID.self) { user in
                return ResponseDeleteUserByID(code: 1000, message: "Delete user successful!", data: user)

            }
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
        throws -> Future<ResponseGetAllPostOfUserByID> {
            return try req
                .parameters.next(User.self)
                .flatMap(to: ResponseGetAllPostOfUserByID.self) { user in
                    return try user.posts.query(on: req).all().map(to: ResponseGetAllPostOfUserByID.self) { posts in
                        return ResponseGetAllPostOfUserByID(code: 1000, message: "Get all posts of user successful!", data: posts)
                    }
            }
    }
    
    func getFriendsOfUserID(_ req: Request)
        throws -> Future<ResponseGetAllFriendsOfUserID> {
            return try req
                .parameters.next(User.self)
                .flatMap(to: ResponseGetAllFriendsOfUserID.self) { user in
                    return try user.friends.query(on: req).all().map(to: ResponseGetAllFriendsOfUserID.self) { friends in
                        return ResponseGetAllFriendsOfUserID(code: 1000, message: "Get all friends of user successful!", data: friends)
                    }
            }
    }
    
    func updateUser(_ req: Request) throws -> Future<ResponseUpdateUser> {
        return try flatMap(
            to: ResponseUpdateUser.self,
            req.parameters.next(User.self),
            req.content.decode(PostUpdateUser.self)) { user, updatedUser in
                user.name = updatedUser.name
                user.username = updatedUser.username
//                user.password = try BCrypt.hash(updatedUser.password)
                user.email = updatedUser.email
                user.phonenumber = updatedUser.phonenumber
                user.idDevice = updatedUser.idDevice
                
            return user.save(on: req).convertToPublic().map(to: ResponseUpdateUser.self) { user in
                
                // save profile picture
                if updatedUser.file?.data != nil {
                    let workPath = try req.make(DirectoryConfig.self).workDir
                    let mediaUploadedPath = workPath + self.profilePictureFolder
                    let folderPath = mediaUploadedPath + ""
                    let fileName = "\(String(describing: user.id!))\(self.suffixImage)"
                    let filePath = folderPath + fileName
                    FileManager().createFile(atPath: filePath,
                                             contents: updatedUser.file!.data,
                                             attributes: nil)
                    user.profilePicture = fileName
                }
                return ResponseUpdateUser(code: 1000, message: "Update user successful!", data: user)
            }
        }
    }
    func updateUserPassword(_ req: Request) throws -> Future<ResponseUpdateUser> {
        return try flatMap(
            to: ResponseUpdateUser.self,
            req.parameters.next(User.self),
            req.content.decode(PostUpdateUserPassword.self)) { user, updatedUser in
                user.password = try BCrypt.hash(updatedUser.password)
                
            return user.save(on: req).convertToPublic().map(to: ResponseUpdateUser.self) { user in
                return ResponseUpdateUser(code: 1000, message: "Update user's password successful!", data: user)
            }
        }
    }
    
    // MARK: Login.
    // http://localhost:8080/api/users/login
    // 1
    func loginHandler(_ req: Request) throws -> Future<ResponseLogin> {
        // 2
        let user = try req.requireAuthenticated(User.self)
        // 3
        let token = try Token.generate(for: user)
        // 4
        return token.save(on: req).map(to: ResponseLogin.self) { savedToken in
            return ResponseLogin(code: 1000, message: "Login successful!", data: savedToken)
        }
    }/*
     1. Define a route handler for logging a user in.
     2. Get the authenticated user from the request. You’ll protect this route with the HTTP basic authentication middleware. This saves the user’s identity in the request’s authentication cache, allowing you to retrieve the user object later. requireAuthenticated(_:) throws an authentication error if there’s no authenticated user.
     3. Create a token for the user.
     4. Save and return the token.
     */
}
