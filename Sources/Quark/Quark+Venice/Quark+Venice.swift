extension Server {
    public init(host: String = "0.0.0.0", port: Int = 8080, reusePort: Bool = false, parser: S4.RequestParser.Type = RequestParser.self, serializer: S4.ResponseSerializer.Type = ResponseSerializer.self, middleware: [Middleware], responder: Responder) throws {
        try self.init(
            host: try TCPHost(host: host, port: port, reusePort: reusePort),
            port: port,
            parser: parser,
            serializer: serializer,
            middleware: middleware,
            responder: responder
        )
    }

    public func start() throws {
        printHeader()
        while true {
            let stream = try host.accept(timingOut: .never)
            co { do { try self.process(stream: stream) } catch { self.failure(error) } }
        }
    }

    public func startInBackground() {
        co { do { try self.start() } catch { self.failure(error) } }
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], filePath: String) throws {
        try self.init(status: status, headers: headers, filePath: filePath, fileType: File.self)
    }
}

extension FileResponder {
    public init(path: String, headers: Headers = [:]) {
        self.init(path: path, headers: headers, fileType: File.self)
    }
}

// Warning: Due to a swift bug this has to be in the same file the protocol is declared
// When we split Venice from Quark this will have to be uncommented

// extension Resource {
//     public var file: FileProtocol.Type {
//         return File.self
//     }
// }
//
// extension Router {
//     public var file: FileProtocol.Type {
//         return File.self
//     }
// }
