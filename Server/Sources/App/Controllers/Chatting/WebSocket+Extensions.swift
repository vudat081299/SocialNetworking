//
//  WebSocket+Extensions.swift
//  App
//
//  Created by Vu Quy Dat on 15/12/2020.
//

import Vapor
import WebSocket
import Foundation

extension WebSocket {
    func send(_ location: Message) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location) else { return }
        send(data)
    }
}
