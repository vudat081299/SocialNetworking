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
    
    func postFriend(_ req: Request, data: FriendCreateData) throws -> Future<Friend> {
        let user = try req.requireAuthenticated(User.self)
        let post = try Friend(
            friendID: data.friendID,
            dateSend: data.dateSend,
            dateAccept: data.dateAccept,
            isBlocked: data.isBlocked,
            isAccept: data.isAccept,
            userID: user.requireID())
        return post.save(on: req)
    }

    func getAllFriends(_ req: Request) throws -> Future<[Friend]> {
        return Friend
            .query(on: req)
            .all()
    }
    
    func putFriendID(_ req: Request) throws -> Future<Friend> {
        return try flatMap(
            to: Friend.self,
            req.parameters.next(Friend.self),
            req.content.decode(FriendCreateData.self)) { post, updatedPost in
                post.friendID = updatedPost.friendID
                post.dateSend = updatedPost.dateSend
                post.dateAccept = updatedPost.dateAccept
                post.isBlocked = updatedPost.isBlocked
                post.isAccept = updatedPost.isAccept
                let user = try req.requireAuthenticated(User.self)
                post.userID = try user.requireID()
                return post.save(on: req)
        }
    }
    
    func deleteFriendID(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Post.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

struct FriendCreateData: Content {
    let friendID: String
    let dateSend: String
    let dateAccept: String
    let isBlocked: String
    let isAccept: String
}
