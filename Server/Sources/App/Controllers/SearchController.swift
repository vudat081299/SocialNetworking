//
//  SearchController.swift
//  App
//
//  Created by Be More on 17/11/2020.
//

import Vapor
import Fluent
import Authentication

struct SearchController: RouteCollection {
    func boot(router: Router) throws {
        
        let searchRouters = router.grouped("api/search")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = searchRouters.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(SearchBody.self, at: "", use: self.searchByKeyword(_:_:))
        tokenAuthGroup.post(String.self, at: "/save_search", use: self.saveSearch(_:_:))
        tokenAuthGroup.post(SaveSearchBody.self, at: "/get_save_search", use: self.getSavedSearch(_:_:))
        tokenAuthGroup.delete(SaveSearch.parameter, use: self.deleteSavedSearch(_:))
        
    }
    
    private func searchByKeyword(_ request: Request, _ data: SearchBody) -> Future<[Post]> {
        return Post.query(on: request).filter(\.content == data.keyword).range(data.index ..< data.count).all()
    }
    
    private func saveSearch(_ request: Request, _ data: String)  -> Future<SaveSearch> {
        let saveData = SaveSearch(keyword: data, created: Date())
        return saveData.save(on: request)
    }
    
    private func getSavedSearch(_ request: Request, _ data: SaveSearchBody) throws -> Future<[SaveSearch]> {
        return  SaveSearch.query(on: request).range(data.index ... data.count).all()
    }
    
    private func deleteSavedSearch(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters.next(SaveSearch.self).delete(on: request).transform(to: .noContent)
    }
    
}

struct SearchBody: Content {
    let keyword: String
    let uid: UUID
    let index: Int
    let count: Int
}

struct SaveSearchBody: Content {
    let index: Int
    let count: Int
}
