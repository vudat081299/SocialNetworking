//
//  SettingController.swift
//  App
//
//  Created by Be More on 19/11/2020.
//

import Foundation
import Vapor
import Fluent
import Authentication

struct SettingController: RouteCollection {
    func boot(router: Router) throws {
        let settingRounter = router.grouped("api/setting")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = settingRounter.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post("", use: self.getSetting(_:))
        tokenAuthGroup.put(Setting.self, at: "set_push_setting", use: self.setSetting(_:_:))
    }
    
    private func getSetting(_ request: Request) -> Future<BaseResponse<Setting>> {
        return Setting.query(on: request).first().unwrap(or: Abort(.notFound)).map { BaseResponse<Setting>(code: .ok, data: $0) }
    }
    
    private func setSetting(_ request: Request, _ data: Setting) -> Future<BaseResponse<Setting>> {
        return data.update(on: request).map { BaseResponse<Setting>(code: .ok, data: $0) }
    }
    
}

