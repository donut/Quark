extension Request {
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], filePath: String, fileType: FileProtocol.Type) throws {
        do {
            var filePath = filePath
            let file: FileProtocol

            // This logic should not be here. It should be defined before calling the initializer.
            // Also use some String extension like String.fileExtension?
            if filePath.split(separator: ".").count == 1 {
                filePath += ".html"
            }

            do {
                file = try fileType.init(path: filePath, mode: .read)
            } catch {
                file = try fileType.init(path: filePath + "html", mode: .read)
            }

            self.init(method: method, uri: uri, headers: headers, body: file.stream)

            if let fileExtension = file.fileExtension, mediaType = mediaType(forFileExtension: fileExtension) {
                self.contentType = mediaType
            }
        } catch {
            throw ClientError.notFound
        }
    }
}
