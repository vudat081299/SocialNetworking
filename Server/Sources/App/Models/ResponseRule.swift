//
//  ResponseRule.swift
//  App
//
//  Created by Vũ Quý Đạt  on 20/12/2020.
//

import Foundation

enum CompassPoint: String {
    case ok = "1000"
    case unexistPost = "9992"
    case existedUser = "9996"
    case existedUser = "9996"
    case unvalidateUser = "9995"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    case existedUser = "9996"
    
    func test () -> String {
        switch self {
        case .ok: return "successful"
        case .south:
            print("Watch out for penguins")
        case .east:
            print("Where the sun rises")
        case .west:
            print("Where the skies are blue")
        }
    }
}
