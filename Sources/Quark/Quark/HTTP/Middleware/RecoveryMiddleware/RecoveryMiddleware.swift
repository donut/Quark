public struct RecoveryMiddleware : Middleware {
    let recover: (ErrorProtocol) throws -> Response

    public init(_ recover: (ErrorProtocol) throws -> Response = RecoveryMiddleware.defaultRecover) {
        self.recover = recover
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        do {
            return try chain.respond(to: request)
        } catch {
            return try recover(error)
        }
    }

    public static func defaultRecover(error: ErrorProtocol) throws -> Response {
        switch error {
        case let error as S4.Error:
            return Response(status: error.status)
        default:
            throw error
        }
    }
}
