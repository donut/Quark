import CURIParser

public enum URIError : ErrorProtocol {
    case invalidURI
}

extension URI {
    public init(_ string: String) throws {
        let parsedURI = parse_uri(string)

        if parsedURI.error == 1 {
            throw URIError.invalidURI
        }

        if parsedURI.field_set & 1 != 0 {
            let string = substring(from: string, start: parsedURI.scheme_start, end: parsedURI.scheme_end)
            scheme = try String(percentEncoded: string)
        } else {
            scheme = nil
        }

        if parsedURI.field_set & 2 != 0 {
            let string = substring(from: string, start: parsedURI.host_start, end: parsedURI.host_end)
            host = try String(percentEncoded: string)
        } else {
            host = nil
        }

        if parsedURI.field_set & 4 != 0 {
            port = Int(parsedURI.port)
        } else {
            port = nil
        }

        if parsedURI.field_set & 8 != 0 {
            let string = substring(from: string, start: parsedURI.path_start, end: parsedURI.path_end)
            path = try String(percentEncoded: string)
        } else {
            path = nil
        }

        if parsedURI.field_set & 16 != 0 {
            query = substring(from: string, start: parsedURI.query_start, end: parsedURI.query_end)
        } else {
            query = nil
        }

        if parsedURI.field_set & 32 != 0 {
            let string = substring(from: string, start: parsedURI.fragment_start, end: parsedURI.fragment_end)
            fragment = try String(percentEncoded: string)
        } else {
            fragment = nil
        }

        if parsedURI.field_set & 64 != 0 {
            let userInfoString = substring(from: string, start: parsedURI.user_info_start, end: parsedURI.user_info_end)
            userInfo = try parse(userInfo: userInfoString)
        } else {
            userInfo = nil
        }

        if scheme == nil &&
            host == nil &&
            port == nil &&
            path == nil &&
            query == nil &&
            fragment == nil &&
            userInfo == nil {
            throw URIError.invalidURI
        }
    }
}

private func substring(from source: String, start: UInt16, end: UInt16) -> String {
    return source[source.index(source.startIndex, offsetBy: Int(start)) ..< source.index(source.startIndex, offsetBy: Int(end))]
}

private func parse(userInfo: String) throws -> URI.UserInfo? {
    let userInfoElements = userInfo.split(separator: ":")

    if userInfoElements.count == 2 {
        let username = try String(percentEncoded: userInfoElements[0])
        let password = try String(percentEncoded: userInfoElements[1])

        return URI.UserInfo(username: username, password: password)
    }

    throw URIError.invalidURI
}

extension URI {
    public var queryDictionary: [String: String] {
        get {
            var queries: [String: String] = [:]

            let queryTuples = query?.split(separator: "&") ?? []

            for tuple in queryTuples {
                let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
                if queryElements.count == 1 {
                    if let key = try? String(percentEncoded: queryElements[0]) {
                        queries[key] = ""
                    }
                } else if queryElements.count == 2 {
                    if let
                        key = try? String(percentEncoded: queryElements[0]),
                        value = try? String(percentEncoded: queryElements[1]) {
                        queries[key] = value
                    }
                }
            }

            return queries
        }

        set(queryDictionary) {
            self.query = queryDictionary.map({
                $0.percentEncoded(allowing: UTF8.uriQueryAllowed) + "=" + $1.percentEncoded(allowing: UTF8.uriQueryAllowed)
            }).joined(separator: "&")
        }
    }

    public var queryComplexDictionary: [String: [String?]] {
        var queries: [String: [String?]] = [:]

        let queryTuples = query?.split(separator: "&") ?? []

        for tuple in queryTuples {
            let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
            if queryElements.count == 1 {
                if let key = try? String(percentEncoded: queryElements[0]) {
                    let values = queries[key] ?? []
                    queries[key] = values + [nil]
                }
            } else if queryElements.count == 2 {
                if let
                    key = try? String(percentEncoded: queryElements[0]),
                    value = try? String(percentEncoded: queryElements[1]) {
                    let values = queries[key] ?? []
                    queries[key] = values + ([value] as [String?])
                }
            }
        }

        return queries
    }
}

extension URI : CustomStringConvertible {
    public var description: String {
        var string = ""

        if let scheme = scheme {
            string += scheme + "://"
        }

        if let userInfo = userInfo {
            string += String(userInfo) + "@"
        }

        if let host = host {
            string += host
        }

        if let port = port {
            string += ":" + String(port)
        }

        if let path = path {
            string += path
        }

        if let query = query, decodedQuery = try? String(percentEncoded: query) {
            string += "?" + decodedQuery
        }

        if let fragment = fragment {
            string += "#" + fragment
        }

        return string
    }
}

extension URI {
    public func percentEncoded() -> String {
        var string = ""

        if let scheme = scheme {
            string += scheme + "://"
        }

        if let userInfo = userInfo?.percentEncoded() {
            string += userInfo + "@"
        }

        if let host = host?.percentEncoded(allowing: UTF8.uriHostAllowed) {
            string += host
        }

        if let port = port {
            string += ":" + String(port)
        }

        if let path = path?.percentEncoded(allowing: UTF8.uriQueryAllowed) {
            string += path
        }

        if let query = query {
            string += "?" + query
        }

        if let fragment = fragment?.percentEncoded(allowing: UTF8.uriFragmentAllowed) {
            string += "#" + fragment
        }

        return string
    }
}

extension URI : Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func == (lhs: URI, rhs: URI) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension URI.UserInfo : Hashable, CustomStringConvertible {
    public var hashValue: Int {
        return description.hashValue
    }

    public var description: String {
        return username + ":" + password
    }

    public func percentEncoded() -> String {
        return username.percentEncoded(allowing: UTF8.uriUserAllowed) + ":"
            + password.percentEncoded(allowing: UTF8.uriUserAllowed)
    }
}

public func == (lhs: URI.UserInfo, rhs: URI.UserInfo) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
