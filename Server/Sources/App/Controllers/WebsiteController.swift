import Vapor
import Leaf
import Authentication

// 1
struct WebsiteController: RouteCollection {
    let imageFolder = "ProfilePictures/"
    
    // 2
    func boot(router: Router) throws {
        // 3
//        router.get(use: indexHandler)
//        // This registers the acronymHandler route for /acronyms/<ACRONYM ID>, similar to the API.
//        router.get("acronyms", Acronym.parameter, use: acronymHandler)
//
//        router.get("users", User.parameter, use: userHandler)
//        router.get("users", use: allUsersHandler)
//
//        router.get("categories", use: allCategoriesHandler)
//        router.get("categories", Category.parameter, use: categoryHandler)
//
//        router.get("acronyms", "create", use: createAcronymHandler)
////        router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
//        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
//
//        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
//        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
//
//        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
//
//        // 1
//        router.get("login", use: loginHandler)
//        // 2
//        router.post(LoginPostData.self, at: "login", use: loginPostHandler)
        /*
         1. Route GET requests for /login to loginHandler(_:).
         2. Route POST requests for /login to loginPostHandler(_:userData:), decoding the request body into LoginPostData.
         */
        
        /// This creates a route group that runs AuthenticationSessionsMiddleware before the route handlers. This middleware reads the cookie from the request and looks up the session ID in the application’s session list. If the session contains a user, AuthenticationSessionsMiddleware adds it to the AuthenticationCache, making the user available later in the process.
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post(RegisterData.self, at: "register", use: registerPostHandler)
        authSessionRoutes.get("users", User.parameter, "profilePicture", use: getUsersProfilePictureHandler)
        
        /// This creates a new route group, extending from authSessionRoutes, that includes RedirectMiddleware. The application runs a request through RedirectMiddleware before it reaches the route handler, but after AuthenticationSessionsMiddleware. This allows RedirectMiddleware to check for an authenticated user. RedirectMiddleware requires you to specify the path for redirecting unauthenticated users and the Authenticatable type to check for. In this case, that’s your User model.
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
        protectedRoutes.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        protectedRoutes.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        protectedRoutes.get("users", User.parameter, "addProfilePicture", use: addProfilePictureHandler)
        protectedRoutes.post("users", User.parameter, "addProfilePicture", use: addProfilePicturePostHandler)
    }
    
        // 4
//        func indexHandler(_ req: Request) throws -> Future<View> {
//            // 5
//            return try req.view().render("index")
//        }
    
    //    func indexHandler(_ req: Request) throws -> Future<View> {
    //        // 1
    //        let context = IndexContext(title: "Home page")
    //        // 2
    //        return try req.view().render("index", context)
    //    }
    /*
     1. Create an IndexContext containing the desired title.
     2. Pass the context to Leaf as the second parameter to render(_:_:).
     */
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        // 1
        return Acronym
            .query(on: req)
            .all()
            .flatMap(to: View.self) { acronyms in
                // 2
//                let acronymsData = acronyms.isEmpty ? nil : acronyms
//                let context = IndexContext(title: "Home page", acronyms: acronymsData)
                
//                let context = IndexContext(title: "Home page", acronyms: acronyms)
                // 1
                let userLoggedIn = try req.isAuthenticated(User.self)
                // 2
//                let context = IndexContext(title: "Home page",
//                                           acronyms: acronyms,
//                                           userLoggedIn: userLoggedIn)
                // 1
                let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
                // 2
                let context = IndexContext(title: "Home page",
                                           acronyms: acronyms,
                                           userLoggedIn: userLoggedIn,
                                           showCookieMessage: showCookieMessage)
                /*
                 1. See if a cookie called cookies-accepted exists. If it doesn’t, set the showCookieMessage flag to true. You can read cookies from the request and set them on a response.
                 2. Pass the flag to IndexContext so the template knows whether to show the message.
                 */
                    
                /*
                 1. Check if the request contains an authenticated user.
                 2. Pass the result to the new flag in IndexContext.
                 */
                return try req
                    .view()
                    .render("index", context)
        }
    }/*
     1. Use a Fluent query to get all the acronyms from the database.
     2. Add the acronyms to IndexContext if there are any, otherwise set the variable to nil. Leaf can check for nil in the template.
     */
    
    // 1
    func acronymHandler(_ req: Request) throws -> Future<View> {
        // 2
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                // 3
                return acronym
                    .user
                    .get(on: req)
                    .flatMap(to: View.self) { user in
                        // 4
//                        let context = AcronymContext(title: acronym.nameEvent, acronym: acronym, user: user)
                        let categories = try acronym.categories.query(on: req).all()
                        let context = AcronymContext(title: acronym.nameEvent, acronym: acronym, user: user, categories: categories)
                        return try req
                            .view()
                            .render("acronym", context)
                }
        }
    }/*
     1. Declare a new route handler, acronymHandler(_:), that returns Future<View>.
     2. Extract the acronym from the request’s parameters and unwrap the result.
     3. Get the user for acronym and unwrap the result.
     4. Create an AcronymContext that contains the appropriate details and render the page using the acronym.leaf template.
     */
    
    // 1
    func userHandler(_ req: Request) throws -> Future<View> {
        // 2
        return try req.parameters.next(User.self)
            .flatMap(to: View.self) { user in
                // 3
                return try user.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in
                        // 4
//                        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                        // 1
                        let loggedInUser = try req.authenticated(User.self)
                        // 2
                        let context = UserContext(title: user.name,
                                                  user: user,
                                                  acronyms: acronyms,
                                                  authenticatedUser: loggedInUser)
                        /*
                         1. Get the authenticated user from Request. This returns User? as there may be no authenticated user.
                         2. Pass the optional, authenticated user to the context.
                         */
                        return try req.view().render("user", context)
                }
        }
    }/*
     1. Define the route handler for the user page that returns Future<View>.
     2. Get the user from the request’s parameters and unwrap the future.
     3. Get the user’s acronyms using the computed property and unwrap the future.
     4. Create a UserContext, then render user.leaf, returning the result. In this case, you’re not setting the acronyms array to nil if it’s empty. This is not required as you’re checking the count in template.
     */
    
    // 1
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        // 2
        return User.query(on: req)
            .all()
            .flatMap(to: View.self) { users in
                // 3
                let context = AllUsersContext(
                    title: "All Users",
                    users: users)
                return try req.view().render("allUsers", context)
        }
    }/*
     1. Define a route handler for the “All Users” page that returns Future<View>.
     2. Get the users from the database and unwrap the future.
     3. Create an AllUsersContext and render the allUsers.leaf template, then return the result.
     */
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        // 1
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)
        // 2
        return try req.view().render("allCategories", context)
    }/*
     1. Create an AllCategoriesContext. Notice that the context includes the query result directly, since Leaf can handle futures.
     2. Render the allCategories.leaf template with the provided context.
     */
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        // 1
        return try req.parameters.next(Category.self)
            .flatMap(to: View.self) { category in
                // 2
                let acronyms = try category.acronyms.query(on: req).all()
                // 3
                let context = CategoryContext(
                    title: category.name,
                    category: category,
                    acronyms: acronyms)
                // 4
                return try req.view().render("category", context)
        }
    }/*
     1. Get the category from the request’s parameters and unwrap the returned future.
     2. Create a query to get all the acronyms for the category. This is a Future<[Acronym]>.
     3. Create a context for the page.
     4. Return a rendered view using the category.leaf template.
     */
    
    func createAcronymHandler(_ req: Request) throws
        -> Future<View> {
            // 1
//            let context = CreateAcronymContext(users: User.query(on: req).all())
//            let context = CreateAcronymContext()

            // 1
            let token = try CryptoRandom()
              .generateData(count: 16)
              .base64EncodedString()
            // 2
            let context = CreateAcronymContext(csrfToken: token)
            // 3
            try req.session()["CSRF_TOKEN"] = token
            /*
             1. Create a token using 16 bytes of randomly generated data, base64 encoded.
             2. Initialize a CreateAcronymContext with the created token.
             3. Save the token into the request’s session under the CSRF_TOKEN key.
             */
            
            // 2
            return try req.view().render("createAcronym", context)
    }/*
     1. Create a context by passing in a query to get all of the users.
     2. Render the page using the createAcronym.leaf template.
     */
    
    //    // 1
    //    func createAcronymPostHandler(
    //        _ req: Request,
    //        acronym: Acronym
    //    ) throws -> Future<Response> {
    //        // 2
    //        return acronym.save(on: req)
    //            .map(to: Response.self) { acronym in
    //                // 3
    //                guard let id = acronym.id else {
    //                    throw Abort(.internalServerError)
    //                }
    //                // 4
    //                return req.redirect(to: "/acronyms/\(id)")
    //        }
    //    }
    /*
     1. Declare a route handler that takes Acronym as a parameter. Vapor automatically decodes the form data to an Acronym object.
     2. Save the provided acronym and unwrap the returned future.
     3. Ensure that the ID has been set, otherwise throw a 500 Internal Server Error.
     4. Redirect to the page for the newly created acronym.
     */
    
    // 1
    func createAcronymPostHandler(_ req: Request, data: CreateAcronymData) throws -> Future<Response> {
        // 1
        let expectedToken = try req.session()["CSRF_TOKEN"]
        // 2
        try req.session()["CSRF_TOKEN"] = nil
        // 3
        guard let csrfToken = data.csrfToken, expectedToken == csrfToken else {
            throw Abort(.badRequest)
        }/*
         1. Get the expected token from the request’s session. This is the token you saved in createAcronymHandler(_:).
         2. Clear the CSRF token now that you’ve used it. You generate a new token with each form.
         3. Ensure the provided token is not nil and matches the expected token; otherwise, throw a 400 Bad Request error.
         */
        
        // 2
//        let acronym = Acronym(nameEvent: data.nameEvent,
//                              date: data.date,
//                              time: data.time,
//                              link: data.link,
//                              userID: data.userID)
        
        // This gets the user from the request using requireAuthenticated(_:), as in the API.
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(nameEvent: data.nameEvent,
                                  date: data.date,
                                  time: data.time,
                                  link: data.link,
                                  userID: user.requireID())
        // 3
        return acronym.save(on: req)
            .flatMap(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                
                // 4
                var categorySaves: [Future<Void>] = []
                // 5
                for category in data.categories ?? [] {
                    try categorySaves.append(
                        Category.addCategory(category, to: acronym, on: req))
                }
                // 6
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves.flatten(on: req)
                    .transform(to: redirect)
        }
    }/*
     1. Change the Content type of route handler to accept CreateAcronymData.
     2. Create an Acronym object to save as it’s no longer passed into the route.
     3. Call flatMap(to:) instead of map(to:) as you now return a Future<Response> in the closure.
     4. Define an array of futures to store the save operations.
     5. Loop through all the categories provided to the request and add the results of Category.addCategory(_:to:on:) to the array.
     6. Flatten the array to complete all the Fluent operations and transform the result to a Response. Redirect the page to the new acronym’s page.
     */
    

    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        // 1
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                // 2
//                let context = EditAcronymContext(acronym: acronym, users: User.query(on: req).all())
//                let users = User.query(on: req).all() // No longer use it.
                let categories = try acronym.categories.query(on: req).all()
//                let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                let context = EditAcronymContext(acronym: acronym,
                                                 categories: categories)
                // 3
                return try req.view().render("createAcronym", context)
        }
    }/*
     1. Get the acronym to edit from the request’s parameter and unwrap the future.
     2. Create a context to edit the acronym, passing in all the users.
     3. Render the page using the createAcronym.leaf template, the same template used for the create page.
     */
    
//    func editAcronymPostHandler(_ req: Request) throws
//      -> Future<Response> {
//      // 1
//      return try flatMap(
//        to: Response.self,
//        req.parameters.next(Acronym.self),
//        req.content.decode(Acronym.self)
//      ) { acronym, data in
//        // 2
//        acronym.nameEvent = data.nameEvent
//        acronym.date = data.date
//        acronym.time = data.time
//        acronym.link = data.link
//        acronym.userID = data.userID
//
//        // 3
//        guard let id = acronym.id else {
//          throw Abort(.internalServerError)
//        }
//        let redirect = req.redirect(to: "/acronyms/\(id)")
//        // 4
//        return acronym.save(on: req).transform(to: redirect)
//      }
//    }
    /*
     1. Use the convenience form of flatMap to get the acronym from the request’s parameter, decode the incoming data and unwrap both results.
     2. Update the acronym with the new data.
     3. Ensure the ID has been set, otherwise throw a 500 Internal Server Error.
     4. Save the result and transform the result to redirect to the updated acronym’s page.
     */
    
    
    
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        // 1
        return try flatMap(to: Response.self, req.parameters.next(Acronym.self), req.content.decode(CreateAcronymData.self)) { acronym, data in
            acronym.nameEvent = data.nameEvent
            acronym.date = data.date
            acronym.time = data.time
            acronym.link = data.link
//            acronym.userID = data.userID
            /// This gets the authenticated user from the request.
            let user = try req.requireAuthenticated(User.self)
            // This uses the authenticated user’s ID for the updated acronym.
            acronym.userID = try user.requireID()
            
            guard let id = acronym.id else {
                throw Abort(.internalServerError)
            }
            
            // 2
            return acronym.save(on: req).flatMap(to: [Category].self) { _ in
                // 3
                try acronym.categories.query(on: req).all()
            }.flatMap(to: Response.self) { existingCategories in
                // 4
                let existingStringArray = existingCategories.map {
                    $0.name
                }
                
                // 5
                let existingSet = Set<String>(existingStringArray)
                let newSet = Set<String>(data.categories ?? [])
                
                // 6
                let categoriesToAdd = newSet.subtracting(existingSet)
                let categoriesToRemove = existingSet
                    .subtracting(newSet)
                
                // 7
                var categoryResults: [Future<Void>] = []
                // 8
                for newCategory in categoriesToAdd {
                    categoryResults.append(
                        try Category.addCategory(newCategory, to: acronym, on: req))
                }
                
                // 9
                for categoryNameToRemove in categoriesToRemove {
                    // 10
                    let categoryToRemove = existingCategories.first {
                        $0.name == categoryNameToRemove
                    }
                    // 11
                    if let category = categoryToRemove {
                        categoryResults.append(acronym.categories.detach(category, on: req))
                    }
                }
                
                let redirect = req.redirect(to: "/acronyms/\(id)")
                // 12
                return categoryResults.flatten(on: req).transform(to: redirect)
            }
        }
    }/*
     1. Change the content type the request decodes to CreateAcronymData.
     2. Use flatMap(to:) on save(on:) but return all the acronym’s categories. Note the chaining of futures instead of nesting them. This helps improve the readability of your code.
     3. Get all categories from the database.
     4. Create an array of category names from the categories in the database.
     5. Create a Set for the categories in the database and another for the categories supplied with the request.
     6. Calculate the categories to add to the acronym and the categories to remove.
     7. Create an array of category operation results.
     8. Loop through all the categories to add and call Category.addCategory(_:to:on:) to set up the relationship. Add each result to the results array.
     9. Loop through all the category names to remove from the acronym.
     10. Get the Category object from the name of the category to remove.
     11. If the Category object exists, use detach(_:on:) to remove the relationship and delete the pivot.
     12. Flatten all the future category results. Transform the result to redirect to the updated acronym’s page.
     */
    
    
    /// This route extracts the acronym from the request’s parameter and calls delete(on:) on the acronym. The route then transforms the result to redirect the page to the home screen.
    func deleteAcronymHandler(_ req: Request) throws
        -> Future<Response> {
            return try req.parameters.next(Acronym.self).delete(on: req)
                .transform(to: req.redirect(to: "/"))
    }
    
    
    // 1
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        // 2
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        // 3
        return try req.view().render("login", context)
    }/*
     1. Define a route handler for the login page that returns a future View.
     2. If the request contains the error parameter, create a context with loginError set to true.
     3. Render the login.leaf template, passing in the context.
     */
    
    
    // 1
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        // 2
        return User.authenticate(username: userData.username,
                                 password: userData.password,
                                 using: BCryptDigest(),
                                 on: req)
            .map(to: Response.self) { user in
                // 3
                guard let user = user else {
                    return req.redirect(to: "/login?error")
                }
                // 4
                try req.authenticateSession(user)
                // 5
                return req.redirect(to: "/")
        }
    }/*
     1. Define the route handler that decodes LoginPostData from the request and returns Future<Response>.
     2. Call authenticate(username:password:using:on:). This checks the username and password against the database and verifies the BCrypt hash. This function returns a nil user in a future if there’s an issue authenticating the user.
     3. Verify authenticate(username:password:using:on:) returned an authenticated user; otherwise, redirect back to the login page to show an error.
     4. Authenticate the request’s session. This saves the authenticated User into the request’s session so Vapor can retrieve it in later requests. This is how Vapor persists authentication when a user logs in.
     5. Redirect to the home page after the login succeeds.
     */
    
    
    // 1
    func logoutHandler(_ req: Request) throws -> Response {
        // 2
        try req.unauthenticateSession(User.self)
        // 3
        return req.redirect(to: "/")
    }/*
     1. Define a route handler that simply returns Response. There’s no asynchronous work in this function so it doesn’t need to return a future.
     2. Call unauthenticateSession(_:) on the request. This deletes the user from the session so it can’t be used to authenticate future requests.
     3. Return a redirect to the index page.
     */
    
    // Like the other routes handlers, this creates a context then calls render(_:_:) to render register.leaf.
    /// Route handler for the registration page.
    func registerHandler(_ req: Request) throws -> Future<View> {
//        let context = RegisterContext()
        
        // This checks the request’s query. If message exists — i.e., the URL is /register?message=some-string — the route handler includes it in the context Leaf uses to render the page.
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        
        return try req.view().render("register", context)
    }
    
    
    // 1
    func registerPostHandler(_ req: Request,
                             data: RegisterData) throws -> Future<Response> {
        
        // This calls validate() on the decoded RegisterData, checking each validator you added previously. validate() can throw ValidationError. In an API, you can let this error propagate back to the user but, on a website, that doesn’t make for a good user experience. In this case, you redirect the user back to the “register” page.
        do {
            try data.validate()
        }
//        catch {
//            return req.future(req.redirect(to: "/register"))
//        }
        // When validation fails, the route handler extracts the message from the ValidationError, escapes it properly for inclusion in a URL, and adds it to the redirect URL. Then, it redirects the user back to the registration page.
        catch (let error) {
            let redirect: String
            if let error = error as? ValidationError,let message = error.reason.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }
        
        
        // 2
        let password = try BCrypt.hash(data.password)
        // 3
        let user = User(name: data.name,
                        username: data.username,
                        password: password)
        // 4
        return user.save(on: req).map(to: Response.self) { user in
            // 5
            try req.authenticateSession(user)
            // 6
            return req.redirect(to: "/")
        }
    }/*
     1. Define a route handler that accepts a request and the decoded RegisterData.
     2. Hash the password submitted to the form.
     3. Create a new User, using the data from the form and the hashed password.
     4. Save the new user and unwrap the returned future.
     5. Authenticate the session for the new user. This automatically logs users in when they register, thereby providing a nice user experience when signing up with the site.
     6. Return a redirect back to the home page.
     */
    
    // This defines a new route handler that renders addProfilePicture.leaf. The route handler also passes the title and the user's name to the template as a dictionary.
    func addProfilePictureHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters
            .next(User.self)
            .flatMap { user in
                try req.view().render(
                    "addProfilePicture",
                    ["title": "Add Profile Picture",
                     "username": user.name])
        }
    }
    
    func addProfilePicturePostHandler(_ req: Request) throws -> Future<Response> {
        // 1
        return try flatMap(to: Response.self,
                           req.parameters.next(User.self),
                           req.content.decode(ImageUploadData.self)) { user, imageData in
                            // 2
                            let workPath = try req.make(DirectoryConfig.self).workDir
                            // 3
                            let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
//                            let name = try "\(user.requireID())).jpg"
                            // 4
                            let path = workPath + self.imageFolder + name
                            // 5
                            FileManager().createFile(atPath: path,
                                                     contents: imageData.picture,
                                                     attributes: nil)
                            // 6
                            user.profilePicture = name
                            // 7
                            let redirect = try req.redirect(to: "/users/\(user.requireID())")
                            return user.save(on: req).transform(to: redirect)
        }
    }/*
     1. Get the user from the parameters and decode the request body to ImageUploadData.
     2. Get the current working directory of the application.
     3. Create a unique name for the profile picture.
     4. Set up the path of the file to save.
     5. Save the file on disk using the path and the image data.
     6. Update the user with the profile picture filename.
     7. Save the updated user and return a redirect to the user’s page.
     */
    
    func getUsersProfilePictureHandler(_ req: Request) throws -> Future<Response> {
        // 1
        return try req.parameters
            .next(User.self)
            .flatMap(to: Response.self) { user in
                // 2
                guard let filename = user.profilePicture else {
                    throw Abort(.notFound)
                }
                // 3
                let path = try req.make(DirectoryConfig.self).workDir + self.imageFolder + filename
                // 4
                return try req.streamFile(at: path)
        }
    }/*
     1. Get the user from the request’s parameters.
     2. Ensure the user has a saved profile picture, otherwise throw a 404 Not Found error.
     3. Construct the path of the user’s profile picture.
     4. Use Vapor’s FileIO function to return the file as a Response. This handles reading the file and returning the correct information to the browser.
     */
    
    
    
    
}/*
 1. Declare a new WebsiteController type that conforms to RouteCollection.
 2. Implement boot(router:) as required by RouteCollection.
 3. Register indexHandler(_:) to process GET requests to the router’s root path, i.e., a request to /.
 4. Implement indexHandler(_:) that returns Future<View>.
 5. Render the index template and return the result. You’ll learn about req.view() in a moment.
 */

/// New type to contain the title.
struct IndexContext: Encodable {
    let title: String
    /// This is an optional array of acronyms; it can be nil as there may be no acronyms in the database.
    let acronyms: [Acronym]
    /// This is the flag you set to tell the template that the request contains a logged in user.
    let userLoggedIn: Bool
    /// This flag indicates to the template whether it should display the cookie consent message.
    let showCookieMessage: Bool
}

// Create a new type to hold the context for this page.
/// This AcronymContext contains a title for the page, the acronym itself and the user who created the acronym.
struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    /// He title of the page, which is the user’s name.
    let title: String
    /// The user object to which the page refers.
    let user: User
    /// The acronyms created by this user.
    let acronyms: [Acronym]
    /// This stores the authenticated user for that request, if one exists.
    let authenticatedUser: User?
}

// Context contains a title and an array of users.
struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    // 1
    let title = "All Categories"
    // 2
    let categories: Future<[Category]>
}/*
 1. Define the page’s title for the template.
 2. Define a future array of categories to display in the page.
 */

struct CategoryContext: Encodable {
    // 1
    let title: String
    // 2
    let category: Category
    // 3
    let acronyms: Future<[Acronym]>
}/*
 1. A title for the page; you’ll set this as the category name.
 2. The category for the page. This isn’t Future<Category> since you need the category’s name to set the title. This means you’ll have to unwrap the future in your route handler.
 3. The category’s acronyms, provided as a future.
 */

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
//    let users: Future<[User]> // This is no longer required as the template doesn’t use users anymore.
    /// This is the CRSF token you’ll pass into the template.
    let csrfToken: String
}

struct EditAcronymContext: Encodable {
    // 1
    let title = "Edit Acronym"
    // 2
    let acronym: Acronym
    // 3
//    let users: Future<[User]>
    // 4
    let editing = true
    let categories: Future<[Category]>

}/*
 1. The title for the page: “Edit Acronym”.
 2. The acronym to edit.
 3. A future array of users to display in the form.
 4. A flag to tell the template that the page is for editing an acronym.
 */

/// This takes the existing information required for an acronym and adds an optional array of Strings to represent the categories. This allows users to submit existing and new categories instead of only existing ones.
struct CreateAcronymData: Content {
//    let userID: User.ID //This is no longer required since you can get it from the authenticated user.
    let nameEvent: String
    let date: String
    let time: String
    let link: String
    let categories: [String]?
    /// This is the CSRF token that the form sends using the hidden input. The token is optional as it's not required by the edit acronym page for now.
    let csrfToken: String?
}

/// This provides the title of the page and a flag to indicate a login error.
struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

/// This new Content type defines the data you expect when you receive the login POST request.
struct LoginPostData: Content {
    let username: String
    let password: String
}

/// Context for the registration page.
struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    
    //This is the message to display on the registration page. Remember that Leaf handles nil gracefully, allowing you to use the default value in the normal case.
    init(message: String? = nil) {
        self.message = message
    }
}

/// This Content type matches the expected data received from the registration POST request. The variables match the names of the inputs in register.leaf.
struct RegisterData: Content {
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
}

// 1
extension RegisterData: Validatable, Reflectable {
  // 2
  static func validations() throws -> Validations<RegisterData> {
    // 3
    var validations = Validations(RegisterData.self)
    // 4
    try validations.add(\.name, .ascii)
    // 5
    try validations.add(\.username,
                        .alphanumeric && .count(3...))
    // 6
    try validations.add(\.password, .count(8...))
    
    
    // If you’ve been following closely, you’ll notice a flaw in the validation: Nothing ensures the passwords match! Vapor’s validation library doesn’t provide a built-in way to check that two strings match. However, it’s easy to add custom validators.
    // 1
    validations.add("passwords match") { model in
        // 2
        guard model.password == model.confirmPassword else {
            // 3
            throw BasicValidationError("passwords don’t match")
        }
    }/*
     1. Use Validation’s add(_:_:) to add a custom validator for RegisterData. This takes a readable description as the first parameter. The second parameter is a closure that should throw if validation fails.
     2. Verify that password and confirmPassword match.
     3. If they don’t, throw BasicValidationError.
     */
    
    
    // 7
    return validations
  }
}/*
 1. Extend RegisterData to make it conform to Validatable and Reflectable. Validatable allows you to validate types with Vapor. Reflectable provides a way to discover the internal components of a type.
 2. Implement validations() as required by Validatable.
 3. Create a Validations instance to contain the various validators.
 4. Add a validator to ensure RegisterData’s name contains only ASCII characters. Note: Be careful when adding restrictions on names like this. Some countries, such as China, don’t have names with ASCII characters.
 5. Add a validator to ensure the username contains only alphanumeric characters and is at least 3 characters long. .count(_:) takes a Swift Range, allowing you to create both open-ended and closed ranges, if required.
 6. Add a validator to ensure the password is at least 8 characters long.
 7. Return the validations for Vapor to test.
 */

struct ImageUploadData: Content {
    var picture: Data
}

extension URL {
    static func createFolder(folderName: String) -> URL? {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        if let documentDirectory = fileManager.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first {
            // Construct a URL with desired folder name
            let folderURL = documentDirectory.appendingPathComponent(folderName)
            // If folder URL does not exist, create it
            if !fileManager.fileExists(atPath: folderURL.path) {
                do {
                    // Attempt to create folder
                    try fileManager.createDirectory(atPath: folderURL.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                } catch {
                    // Creation failed. Print error & return nil
                    print(error.localizedDescription)
                    return nil
                }
            }
            // Folder either exists, or was created. Return URL
            return folderURL
        }
        // Will only be called if document directory not found
        return nil
    }
}
