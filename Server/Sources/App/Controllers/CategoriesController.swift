import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoute = router.grouped("api", "categories")
        
        categoriesRoute.get(use: getAllCategories)
        categoriesRoute.get(Category.parameter, use: getCategoryID)
//        categoriesRoute.post(Category.self, use: addCategory)
        
        /// This uses the token middleware to protect category creation, just like creating an acronym, ensuring only authenticated users can create categories.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(Category.self, use: addCategory)
        
        categoriesRoute.delete(Category.parameter, use: deleteCategoryID)
        
        categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsOfCategoryID)
    }
    
    func addCategory(_ req: Request, category: Category) throws -> Future<Category> {
        return category
            .save(on: req)
    }
    
    func getAllCategories(_ req: Request) throws -> Future<[Category]> {
        return Category
            .query(on: req)
            .all()
    }
    
    func getCategoryID(_ req: Request) throws -> Future<Category> {
        return try req
            .parameters
            .next(Category.self)
    }
    
    func deleteCategoryID(_ req: Request) throws -> Future<HTTPStatus> {
           return try req
               .parameters
               .next(Category.self)
               .delete(on: req)
               .transform(to: .noContent)
       }
    
    // http://localhost:8080/api/categories/<categoryID>/acronyms
    func getAcronymsOfCategoryID(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(Category.self)
            .flatMap(to: [Acronym].self) { category in
                try category
                    .acronyms
                    .query(on: req)
                    .all()
        }
    }
}







