import Vapor
import Fluent
import Authentication

struct FriendsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "friends")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.get(use: getAllFriends)
        tokenAuthGroup.post(FriendCreateData.self, use: postFriend)
        tokenAuthGroup.put(Friend.parameter, use: putFriendID)
        tokenAuthGroup.delete(Friend.parameter, use: deleteFriendID)
    }
    
    func postFriend(_ req: Request, data: FriendCreateData) throws -> Future<ResponseFriendRequest> {
        let user = try req.requireAuthenticated(User.self)
        let post = try Friend(
            userID: user.requireID(),
            friendID: UUID(data.friendID)!,
            sumUserID: try user.requireID().uuidString > data.friendID ? "\(user.requireID().uuidString)\(data.friendID)" : "\(data.friendID)\(user.requireID().uuidString)",
            dateSend: data.dateSend,
            dateAccept: data.dateAccept,
            isBlocked: data.isBlocked,
            isAccept: data.isAccept)
        return post.save(on: req).map(to: ResponseFriendRequest.self) { friendRequest in
            return ResponseFriendRequest(code: 1000, message: "Send friend request successful!", data: friendRequest)
        }
    }

    func getAllFriends(_ req: Request) throws -> Future<ResponseGetAllFriends> {
        return Friend
            .query(on: req)
            .all()
            .map(to: ResponseGetAllFriends.self) { friends in
                return ResponseGetAllFriends(code: 1000, message: "Get all friends successful!", data: friends)
            }
    }
    
    func putFriendID(_ req: Request) throws -> Future<ResponseUpdateFriend> {
        let user = try req.requireAuthenticated(User.self)
        return try flatMap(
            to: ResponseUpdateFriend.self,
            req.parameters.next(Friend.self),
            req.content.decode(FriendCreateData.self)) { post, updatedPost in
                post.friendID = UUID(updatedPost.friendID)!
                post.userID = try user.requireID()
                post.sumUserID = try user.requireID().uuidString > updatedPost.friendID ? "\(user.requireID().uuidString)\(updatedPost.friendID)" : "\(updatedPost.friendID)\(user.requireID().uuidString)"
                post.dateSend = updatedPost.dateSend
                post.dateAccept = updatedPost.dateAccept
                post.isBlocked = updatedPost.isBlocked
                post.isAccept = updatedPost.isAccept
            return post.save(on: req).map(to: ResponseUpdateFriend.self) { editedFriend in
                return ResponseUpdateFriend(code: 1000, message: "Edit friend successful!", data: editedFriend)
            }
        }
    }
    // original
//    func deleteFriendID(_ req: Request) throws -> Future<HTTPStatus> {
//        return try req
//            .parameters
//            .next(Friend.self)
//            .delete(on: req)
//            .transform(to: .noContent)
//    }
    func deleteFriendID(_ req: Request) throws -> Future<ResponseDeleteFriend> {
        return try req
            .parameters
            .next(Friend.self)
            .delete(on: req)
            .map(to: ResponseDeleteFriend.self) { friend in
                return ResponseDeleteFriend(code: 1000, message: "Delete friend successful!", data: friend)
            }
    }
    
}
