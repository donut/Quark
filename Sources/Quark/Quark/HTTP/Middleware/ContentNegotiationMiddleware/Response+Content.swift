extension Response {
    public var content: StructuredData? {
        get {
            return storage["content"] as? StructuredData
        }

        set(content) {
            storage["content"] = content
        }
    }

    public init(status: Status = .ok, headers: Headers = [:], content: StructuredDataRepresentable, didUpgrade: DidUpgrade? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: [],
            didUpgrade: didUpgrade
        )

        self.content = content.structuredData
    }

    public init<T: StructuredDataRepresentable>(status: Status = .ok, headers: Headers = [:], contentOptional: T?, didUpgrade: DidUpgrade? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: [],
            didUpgrade: didUpgrade
        )

        self.content = contentOptional.structuredData
    }

    public init<T: StructuredDataRepresentable>(status: Status = .ok, headers: Headers = [:], contentArray: [T], didUpgrade: DidUpgrade? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: [],
            didUpgrade: didUpgrade
        )

        self.content = contentArray.structuredData
    }

    public init<T: StructuredDataRepresentable>(status: Status = .ok, headers: Headers = [:], contentDictionary: [String: T], didUpgrade: DidUpgrade? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: [],
            didUpgrade: didUpgrade
        )

        self.content = contentDictionary.structuredData
    }

    public init(status: Status = .ok, headers: Headers = [:], content: StructuredDataFallibleRepresentable, didUpgrade: DidUpgrade? = nil) throws {
        self.init(
            status: status,
            headers: headers,
            body: [],
            didUpgrade: didUpgrade
        )

        self.content = try content.asStructuredData()
    }
}
