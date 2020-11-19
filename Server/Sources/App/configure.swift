import FluentMySQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first.
    try services.register(FluentMySQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router.
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware.
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self) // This registers the sessions middleware as a global middleware for your application.
    services.register(middlewares)
    services.register(NIOServerConfig.default(maxBodySize: 20_000_000)) // Configure size of file upload. byte.
    
//    if env == .development {
//            services.register(Server.self) { container -> EngineServer in
//                var serverConfig = try container.make() as EngineServerConfig
//                serverConfig.port = 8989
//                serverConfig.hostname = "192.168.31.215"
//                let server = EngineServer(
//                    config: serverConfig,
//                    container: container
//                )
//                return server
//            }
//        }

    // Configure a SQLite database.
//    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
//    var databases = DatabasesConfig()
//    databases.add(database: sqlite, as: .sqlite)
//    services.register(databases)
    
    var databases = DatabasesConfig()
    
    // This sets properties for the database name and port depending on the environment. We will use different names and ports for testing and running the application.
    let databaseName: String
    let databasePort: Int
    let databaseUsername: String
    if (env == .testing) {
        databaseName = "vapor"
        databasePort = 3306
        databaseUsername = "vapor"
    } else {
        databaseName = "vapor"
        databasePort = 3306
        databaseUsername = "vapor"
    }

    // Update app’s configuration to support testing.
    // This sets the database port and name from the properties set above. These changes allow you to run your tests on a database other than your production database. This ensures you start each test in a known state and don’t destroy live data. Since you’re using Docker to host your database, setting up another database on the same machine is simple.
    let databaseConfig = MySQLDatabaseConfig(
        hostname: "localhost",
        port: databasePort,
        username: databaseUsername,
        password: "password",
        database: databaseName)
    let database = MySQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .mysql)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
//    migrations.add(model: Todo.self, database: .sqlite)
    // Linking the acronym’s userID property to the User table( see foreign key constraints in Acronym file, so must create the User table first.
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Acronym.self, database: .mysql)
    migrations.add(model: Post.self, database: .mysql)
    migrations.add(model: Friend.self, database: .mysql)
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: AcronymCategoryPivot.self, database: .mysql)
    migrations.add(model: Token.self, database: .mysql)
    migrations.add(model: SaveSearch.self, database: .mysql)
    migrations.add(model: Setting.self, database: .mysql)
    
    // This adds AdminUser to the list of migrations so the app executes the migration at the next app launch. You use add(migration:database:) instead of add(model:database:) since this isn’t a full model.
    migrations.add(migration: AdminUser.self, database: .mysql)
    migrations.add(migration: DefaultSetting.self, database: .mysql)
    
    services.register(migrations)
    
    
    // This adds the Fluent commands to your application, which allows you to manually run migrations. It also allows you to revert your migrations.
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    // This tells Vapor to use LeafRenderer when asked for a ViewRenderer type.
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    // This tells your application to use MemoryKeyedCache when asked for the KeyedCache service. The KeyedCache service is a key-value cache that backs sessions.
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}
