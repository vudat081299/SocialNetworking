import FluentSQLite

import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(AuthenticationProvider())
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self) // This registers the sessions middleware as a global middleware for your application.
    services.register(middlewares)
    services.register(NIOServerConfig.default(maxBodySize: 1_000_000)) // Configure size of file upload. byte.
    
    services.register(Server.self) { container -> NIOServer in
        var serverConfig = try container.make() as NIOServerConfig
        serverConfig.port = 2408
        serverConfig.hostname = "localhost"
        let server = NIOServer(
            config: serverConfig,
            container: container
        )
        return server
    }
    
    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)
    
    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(model: Token.self, database: .sqlite)
    
    services.register(migrations)
    
    // This tells your application to use MemoryKeyedCache when asked for the KeyedCache service. The KeyedCache service is a key-value cache that backs sessions.
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}
