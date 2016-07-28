import CHTTPParser

typealias RequestContext = UnsafeMutablePointer<RequestParserContext>

struct RequestParserContext {
    var method: Method! = nil
    var uri: URI! = nil
    var version: Version = Version(major: 0, minor: 0)
    var headers: Headers = Headers([:])
    var body: Data = []

    var currentURI = ""
    var buildingHeaderName = ""
    var currentHeaderName: CaseInsensitiveString = ""
    var completion: (Request) -> Void

    init(completion: (Request) -> Void) {
        self.completion = completion
    }
}

var requestSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_url              = onRequestURL
    settings.on_header_field     = onRequestHeaderField
    settings.on_header_value     = onRequestHeaderValue
    settings.on_headers_complete = onRequestHeadersComplete
    settings.on_body             = onRequestBody
    settings.on_message_complete = onRequestMessageComplete

    return settings
}()

public final class RequestParser : S4.RequestParser {
    let stream: Stream
    let context: RequestContext
    var parser = http_parser()
    var request: Request?

    public init(stream: Stream) {
        self.stream = stream
        self.context = RequestContext.allocate(capacity: 1)
        self.context.initialize(to: RequestParserContext { request in
            self.request = request
        })

        resetParser()
    }

    deinit {
        context.deallocate(capacity: 1)
    }

    func resetParser() {
        http_parser_init(&parser, HTTP_REQUEST)
        parser.data = UnsafeMutableRawPointer(context)
    }

    public func parse() throws -> Request {
        while true {
            defer {
                request = nil
            }

            let data = try stream.receive(upTo: 2048)
            let bytesParsed = http_parser_execute(&parser, &requestSettings, UnsafePointer(data.bytes), data.count)

            guard bytesParsed == data.count else {
                resetParser()
                let errorName = http_errno_name(http_errno(parser.http_errno))!
                let errorDescription = http_errno_description(http_errno(parser.http_errno))!
                let error = ParseError(description: "\(String(validatingUTF8: errorName)!): \(String(validatingUTF8: errorDescription)!)")
                throw error
            }

            if let request = request {
                resetParser()
                return request
            }
        }
    }
}

func onRequestURL(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        guard let uri = String(pointer: data!, length: length) else {
            return 1
        }

        $0.currentURI += uri
        return 0
    }
}

func onRequestHeaderField(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        guard let headerName = String(pointer: data!, length: length) else {
            return 1
        }

        if $0.currentHeaderName != "" {
            $0.currentHeaderName = ""
        }

        $0.buildingHeaderName += headerName
        return 0
    }
}

func onRequestHeaderValue(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        guard let headerValue = String(pointer: data!, length: length) else {
            return 1
        }

        if $0.currentHeaderName == "" {
            $0.currentHeaderName = CaseInsensitiveString($0.buildingHeaderName)
            $0.buildingHeaderName = ""

            if $0.headers[$0.currentHeaderName] != nil {
                let previousHeaderValue = $0.headers[$0.currentHeaderName] ?? ""
                $0.headers[$0.currentHeaderName] = previousHeaderValue + ", "
            }
        }

        let previousHeaderValue = $0.headers[$0.currentHeaderName] ?? ""
        $0.headers[$0.currentHeaderName] = previousHeaderValue + headerValue

        return 0
    }
}

func onRequestHeadersComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        $0.method = Method(code: Int(parser!.pointee.method))
        let major = Int(parser!.pointee.http_major)
        let minor = Int(parser!.pointee.http_minor)
        $0.version = Version(major: major, minor: minor)

        guard let uri = try? URI($0.currentURI) else {
            return 1
        }

        $0.uri = uri
        $0.currentURI = ""
        $0.buildingHeaderName = ""
        $0.currentHeaderName = ""
        return 0
    }
}

func onRequestBody(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data), count: length)
        $0.body += Data(Array(buffer))
        return
    }

    return 0
}

func onRequestMessageComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestContext.self).pointee.withPointee {
        let request = Request(
            method: $0.method,
            uri: $0.uri,
            version: $0.version,
            headers: $0.headers,
            body: .buffer($0.body)
        )

        $0.completion(request)

        $0.method = nil
        $0.uri = nil
        $0.version = Version(major: 0, minor: 0)
        $0.headers = Headers([:])
        $0.body = []
        return 0
    }
}
