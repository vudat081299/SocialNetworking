//
//  SessionManager.swift
//  App
//
//  Created by Vu Quy Dat on 15/12/2020.
//

import Vapor
import WebSocket

final class TrackingSessionManager {
    // MARK: Member Variables
    
    private(set) var sessions: LockedDictionary<TrackingSession, [WebSocket]> = [:]
    
    // MARK: Observer Interactions
    
    func add(listener: WebSocket, to session: TrackingSession) {
        guard var listeners = sessions[session] else { return }
        listeners.append(listener)
        sessions[session] = listeners
        
        listener.onClose.always { [weak self, weak listener] in
            guard let listener = listener else { return }
            self?.remove(listener: listener, from: session)
        }
    }
    
    func remove(listener: WebSocket, from session: TrackingSession) {
        guard var listeners = sessions[session] else { return }
        listeners = listeners.filter { $0 !== listener }
        sessions[session] = listeners
    }
    
    // MARK: Poster Interactions
    
    func createTrackingSession(for request: Request) -> Future<TrackingSession> {
        return wordKey(with: request)
            .flatMap(to: TrackingSession.self) { [unowned self] key -> Future<TrackingSession> in
                let session = TrackingSession(id: key)
                guard self.sessions[session] == nil else {
                    return self.createTrackingSession(for: request)
                    
                }
                self.sessions[session] = []
                return Future.map(on: request) { session }
        }
    }
    
    func update(_ location: Location, for session: TrackingSession) {
        guard let listeners = sessions[session] else { return }
        listeners.forEach { ws in ws.send(location) }
    }
    
    func close(_ session: TrackingSession) {
        guard let listeners = sessions[session] else { return }
        listeners.forEach { ws in
            ws.close()
        }
        sessions[session] = nil
    }
}
