//
//  BaseResponse.swift
//  App
//
//  Created by Be More on 17/11/2020.
//

import Foundation
import Vapor

enum Code: Int {
    
    case ok = 1000
    case post_is_not_existed = 9992
    case code_verify_is_incorrect = 9993
    case user_is_not_validated = 9995
    case user_existed = 9996
    case method_is_invalid = 9997
    case token_is_invalid = 9998
    case parameter_is_not_enought = 1002
    case paramerter_value_is_invalid = 1004
    case file_zize_is_too_big = 1006
    
    var description: String {
        
        switch self {
        case .ok:
            return "ok"
        case .post_is_not_existed:
            return "post is not existed"
        case .code_verify_is_incorrect:
            return "code verify is incorrect"
        case .user_is_not_validated:
            return "user is not validated"
        case .user_existed:
            return "user existed"
        case .method_is_invalid:
            return "method is invalid"
        case .token_is_invalid:
            return "token is invalid"
        case .parameter_is_not_enought:
            return "parameter is not enought"
        case .paramerter_value_is_invalid:
            return "paramerter value is invalid"
        case .file_zize_is_too_big:
            return "file zize is too big"
        }
        
    }
    
}

struct BaseResponse<T>: Content, Error where T: Content {
    let code: Int
    let message: String
    let data: T?
    
    init(code: Code, data: T?) {
        self.code = code.rawValue
        self.message = code.description
        self.data = data
    }
}
