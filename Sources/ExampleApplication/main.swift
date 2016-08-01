@_exported import Quark
@_exported import ExampleDomain

struct ServerConfiguration : Configuration {
    let host: String
    let port: Int
}

struct AppConfiguration : Configuration {
    let server: ServerConfiguration
}

print(environment.variables)

configure { (configuration: StructuredData) in
    let store = InMemoryStore()
    let app = Application(store: store)
    return Router(app: app)
}
