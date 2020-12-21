//
//  ResponseRule.swift
//  App
//
//  Created by Vũ Quý Đạt  on 20/12/2020.
//

import Foundation

class BaseR: Codable {
    var code: Int = 0
    var message: String = ""
    
    init(_ code: ResponseRule) {
        self.code = code.rawValue
        self.message = code.text
    }
}

enum ResponseRule: Int {
    
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
    
    var text: String {
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
    
//    func test () -> String {
//        switch self {
//        case .ok: return "successful"
//        case .south:
//            print("Watch out for penguins")
//        case .east:
//            print("Where the sun rises")
//        case .west:
//            print("Where the skies are blue")
//        }
//    }
}
