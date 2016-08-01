public enum AuthenticationResult {
    case accessDenied
    case authenticated
    case payload(key: String, value: Any)
}

enum AuthenticationType {
    case server(realm: String?, authenticate: (username: String, password: String) throws -> AuthenticationResult)
    case client(username: String, password: String)
}

public struct BasicAuthMiddleware : Middleware {
    let type: AuthenticationType

    public init(realm: String? = nil, authenticate: (username: String, password: String) throws -> AuthenticationResult) {
        type = .server(realm: realm, authenticate: authenticate)
    }

    public init(username: String, password: String) {
        type = .client(username: username, password: password)
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        switch type {
        case .server(let realm, let authenticate):
            return try serverRespond(request, chain: chain, realm: realm, authenticate: authenticate)
        case .client(let username, let password):
            return try clientRespond(request, chain: chain, username: username, password: password)
        }
    }

    public func serverRespond(_ request: Request, chain: Responder, realm: String? = nil, authenticate: (username: String, password: String) throws -> AuthenticationResult) throws -> Response {
        var deniedResponse : Response
        if let realm = realm {
            deniedResponse = Response(status: .unauthorized, headers: ["WWW-Authenticate": "Basic realm=\"\(realm)\""])
        } else {
            deniedResponse = Response(status: .unauthorized)
        }

        guard let authorization = request.authorization else {
            return deniedResponse
        }

        let tokens = authorization.split(separator: " ")

        guard tokens.count == 2 || tokens.first == "Basic" else {
            return deniedResponse
        }

        let decodedData = Base64.decode(tokens[1])
        let decodedCredentials = try String(data: decodedData)
        let credentials = decodedCredentials.split(separator: ":")

        guard credentials.count == 2 else {
            return deniedResponse
        }

        let username = credentials[0]
        let password = credentials[1]

        switch try authenticate(username: username, password: password) {
        case .accessDenied:
            return deniedResponse
        case .authenticated:
            return try chain.respond(to: request)
        case .payload(let key, let value):
            var request = request
            request.storage[key] = value
            return try chain.respond(to: request)
        }
    }

    public func clientRespond(_ request: Request, chain: Responder, username: String, password: String) throws -> Response {
        var request = request
        let credentials = Base64.encode("\(username):\(password)")
        request.authorization = "Basic \(credentials))"
        return try chain.respond(to: request)
    }
}
