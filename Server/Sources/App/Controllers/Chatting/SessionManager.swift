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
    
//    func createTrackingSession(for request: Request) -> Future<TrackingSession> {
//        return wordKey(with: request)
//            .flatMap(to: TrackingSession.self) { [unowned self] key -> Future<TrackingSession> in
//                let session = TrackingSession(id: key)
//                guard self.sessions[session] == nil else {
//                    return self.createTrackingSession(for: request)
//                }
//                self.sessions[session] = []
//                return Future.map(on: request) { session }
//        }
//    }
    
    func createTrackingSessionForIndivisualUser(for userID: String) -> ResponseCreateWS {
        let session = TrackingSession(id: userID)
        guard self.sessions[session] == nil else {
            return ResponseCreateWS(code: 1010, message: "Session already exist!", data: InFoWS(id: userID, roomID: 0))
        }
        self.sessions[session] = []
        return ResponseCreateWS(code: 1000, message: "Successful!", data: InFoWS(id: userID, roomID: 0))
    }
    
    func createTrackingSession(for form: CreatedSocketForm, roomID: Int, userID: String) -> ResponseCreateWS {
        let id = form.from > form.to ? "\(form.from)\(form.to)" : "\(form.to)\(form.from)"
        let session = TrackingSession(id: id)
        print("WS: \(id)")
        guard self.sessions[session] == nil else {
            return ResponseCreateWS(code: 1010, message: "Session already exist!", data: InFoWS(id: id, roomID: roomID))
        }
        self.sessions[session] = []
        return ResponseCreateWS(code: 1000, message: "Successful!", data: InFoWS(id: id, roomID: roomID))
    }
    
    func update(_ location: String, for session: TrackingSession, to userID: String = "") {
        guard let listeners = sessions[session] else { return }
        listeners.forEach { ws in ws.send(location) }
        
//        let notifySession = TrackingSession(id: userID)
//        guard let notifyListeners = sessions[notifySession] else { return }
//        notifyListeners.forEach { ws in ws.send(location) }
    }
    
    func notify(to userID: String = "", content: String) {
        let notifySession = TrackingSession(id: userID)
        guard let notifyListeners = sessions[notifySession] else { return }
        notifyListeners.forEach { ws in ws.send(content) }
    }
    
    func close(_ session: TrackingSession) {
        guard let listeners = sessions[session] else { return }
        listeners.forEach { ws in
            ws.close()
        }
        sessions[session] = nil
    }
}
