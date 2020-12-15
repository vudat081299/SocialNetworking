//
//  TrackingSession.swift
//  App
//
//  Created by Vu Quy Dat on 15/12/2020.
//

import Vapor

struct TrackingSession: Content, Hashable {
    let id: String
}

extension TrackingSession: Parameter {
    static func resolveParameter(_ parameter: String, on container: Container) throws -> TrackingSession {
        return .init(id: parameter)
    }
}

