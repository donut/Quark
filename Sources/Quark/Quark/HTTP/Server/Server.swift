public struct Server {
    public let host: Host
    public let port: Int
    public let parser: S4.RequestParser.Type
    public let serializer: S4.ResponseSerializer.Type
    public let middleware: [Middleware]
    public let responder: Responder

    public let bufferSize: Int = 2048

    public init(
        host: Host,
        port: Int,
        parser: S4.RequestParser.Type,
        serializer: S4.ResponseSerializer.Type,
        middleware: [Middleware],
        responder: Responder
        ) throws {
        self.host = host
        self.port = port
        self.parser = parser
        self.serializer = serializer
        self.middleware = middleware
        self.responder = responder
    }
}

extension Server {
    public func process(stream: Stream) throws {
        let parser = self.parser.init(stream: stream)
        let serializer = self.serializer.init(stream: stream)

        while !stream.closed {
            do {
                let request = try parser.parse()
                let response = try middleware.chain(to: responder).respond(to: request)
                try serializer.serialize(response)

                if let upgrade = response.didUpgrade {
                    try upgrade(request, stream)
                    try stream.close()
                }

                if !request.isKeepAlive {
                    try stream.close()
                }
            } catch SystemError.brokenPipe {
                break
            } catch {
                if stream.closed {
                    break
                }
                if let response = Server.recover(error: error) {
                    try serializer.serialize(response)
                } else {
                    let response = Response(status: .internalServerError)
                    try serializer.serialize(response)
                    throw error
                }
            }
        }
    }

    private static func recover(error: Error) -> Response? {
        switch error {
        case ClientError.badRequest:
            return Response(status: .badRequest)
        case ClientError.unauthorized:
            return Response(status: .unauthorized)
        case ClientError.paymentRequired:
            return Response(status: .paymentRequired)
        case ClientError.forbidden:
            return Response(status: .forbidden)
        case ClientError.notFound:
            return Response(status: .notFound)
        case ClientError.methodNotAllowed:
            return Response(status: .methodNotAllowed)
        case ClientError.notAcceptable:
            return Response(status: .notAcceptable)
        case ClientError.proxyAuthenticationRequired:
            return Response(status: .proxyAuthenticationRequired)
        case ClientError.requestTimeout:
            return Response(status: .requestTimeout)
        case ClientError.conflict:
            return Response(status: .conflict)
        case ClientError.gone:
            return Response(status: .gone)
        case ClientError.lengthRequired:
            return Response(status: .lengthRequired)
        case ClientError.preconditionFailed:
            return Response(status: .preconditionFailed)
        case ClientError.requestEntityTooLarge:
            return Response(status: .requestEntityTooLarge)
        case ClientError.requestURITooLong:
            return Response(status: .requestURITooLong)
        case ClientError.unsupportedMediaType:
            return Response(status: .unsupportedMediaType)
        case ClientError.requestedRangeNotSatisfiable:
            return Response(status: .requestedRangeNotSatisfiable)
        case ClientError.expectationFailed:
            return Response(status: .expectationFailed)
        case ClientError.imATeapot:
            return Response(status: .imATeapot)
        case ClientError.authenticationTimeout:
            return Response(status: .authenticationTimeout)
        case ClientError.enhanceYourCalm:
            return Response(status: .enhanceYourCalm)
        case ClientError.unprocessableEntity:
            return Response(status: .unprocessableEntity)
        case ClientError.locked:
            return Response(status: .locked)
        case ClientError.failedDependency:
            return Response(status: .failedDependency)
        case ClientError.preconditionRequired:
            return Response(status: .preconditionRequired)
        case ClientError.tooManyRequests:
            return Response(status: .tooManyRequests)
        case ClientError.requestHeaderFieldsTooLarge:
            return Response(status: .requestHeaderFieldsTooLarge)

        case ServerError.internalServerError:
            return Response(status: .internalServerError)
        case ServerError.notImplemented:
            return Response(status: .notImplemented)
        case ServerError.badGateway:
            return Response(status: .badGateway)
        case ServerError.serviceUnavailable:
            return Response(status: .serviceUnavailable)
        case ServerError.gatewayTimeout:
            return Response(status: .gatewayTimeout)
        case ServerError.httpVersionNotSupported:
            return Response(status: .httpVersionNotSupported)
        case ServerError.variantAlsoNegotiates:
            return Response(status: .variantAlsoNegotiates)
        case ServerError.insufficientStorage:
            return Response(status: .insufficientStorage)
        case ServerError.loopDetected:
            return Response(status: .loopDetected)
        case ServerError.notExtended:
            return Response(status: .notExtended)
        case ServerError.networkAuthenticationRequired:
            return Response(status: .networkAuthenticationRequired)

        default:
            return nil
        }
    }

    public static func log(error: Error) -> Void {
        print("Error: \(error)")
    }

    public func printHeader() {
        var header = "\n"
        header += "\n"
        header += "\n"
        header += "                             _____\n"
        header += "     ,.-``-._.-``-.,        /__  /  ___ _      ______\n"
        header += "    |`-._,.-`-.,_.-`|         / /  / _ \\ | /| / / __ \\\n"
        header += "    |   |ˆ-. .-`|   |        / /__/  __/ |/ |/ / /_/ /\n"
        header += "    `-.,|   |   |,.-`       /____/\\___/|__/|__/\\____/ (c)\n"
        header += "        `-.,|,.-`           -----------------------------\n"
        header += "\n"
        header += "================================================================================\n"
        header += "Started HTTP server, listening on port \(port)."
        print(header)
    }
}
