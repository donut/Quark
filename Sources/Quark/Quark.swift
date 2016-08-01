@_exported import C7
@_exported import S4

public enum QuarkError : ErrorProtocol {
    case invalidConfiguration(description: String)
    case invalidArgument(description: String)
}

extension QuarkError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidConfiguration(let description):
            return description
        case .invalidArgument(let description):
            return description
        }
    }
}

public var configuration: StructuredData = nil {
    willSet(configuration) {
        do {
            let file = try File(path: "/tmp/QuarkConfiguration", mode: .truncateWrite)
            let serializer = JSONStructuredDataSerializer()
            let data = try serializer.serialize(configuration)
            try file.write(data)
        } catch {
            fatalError(String(error))
        }
    }
}

public typealias Configuration = StructuredDataInitializable

public protocol ConfigurableServer {
    init(middleware: [Middleware], responder: Responder, configuration: StructuredData) throws
    func start() throws
}

extension Server : ConfigurableServer {
    public init(middleware: [Middleware], responder: Responder, configuration: StructuredData) throws {
        let host = configuration["server", "host"]?.asString ?? "127.0.0.1"
        let port = configuration["server", "port"]?.asInt ?? 8080
        let reusePort = configuration["server", "reusePort"]?.asBool ?? false

        try self.init(
            host: host,
            port: port,
            reusePort: reusePort,
            middleware: middleware,
            responder: responder
        )
    }
}

public func configure<Config : Configuration>(configurationFile: String = "Configuration.swift", server: ConfigurableServer.Type = Server.self, configure: (Config) throws -> ResponderRepresentable) {
    do {
        let configuration = try loadConfiguration(configurationFile: configurationFile)
        let responder = try configure(Config(structuredData: configuration))
        try config(server: server, responder: responder.responder, configuration: configuration)
    } catch {
        print(error)
    }
}

private func config(server: ConfigurableServer.Type, responder: Responder, configuration: StructuredData) throws {
    var middleware: [Middleware] = []

    if configuration["server", "log"]?.asBool == true {
        middleware.append(LogMiddleware())
    }

    middleware.append(SessionMiddleware())
    middleware.append(ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self]))

    try server.init(
        middleware: middleware,
        responder: responder,
        configuration: configuration
    ).start()
}

private func loadConfiguration(configurationFile: String) throws -> StructuredData {
    var configuration: StructuredData = [:]

    guard case .dictionary(let environmentVariables) = try load(environmentVariables: environment.variables) else {
        throw QuarkError.invalidConfiguration(description: "Configuration from environment variables is not in dictionary format.")
    }

#if Xcode
    let arguments: [String] = []
#else
    let arguments = Array(Process.arguments.suffix(from: 1))
#endif

    guard case .dictionary(let commandLineArguments) = try load(commandLineArguments: arguments) else {
        throw QuarkError.invalidConfiguration(description: "Configuration from command line arguments is not in dictionary format.")
    }

    if let workingDirectory = commandLineArguments["workingDirectory"]?.asString ?? environmentVariables["workingDirectory"]?.asString {
        try File.changeWorkingDirectory(path: workingDirectory)
    }

    guard case .dictionary(let configurationFile) = try load(configurationFile: configurationFile) else {
        throw QuarkError.invalidConfiguration(description: "Configuration from file is not in dictionary format.")
    }

    for (key, value) in configurationFile {
        try configuration.set(value: value, at: key)
    }

    for (key, value) in commandLineArguments {
        let indexPath = key.split(separator: ".").map({$0 as IndexPathElement})
        try configuration.set(value: value, at: indexPath)
    }

    for (key, value) in environmentVariables {
        try configuration.set(value: value, at: key)
    }

    return configuration
}

private func load(configurationFile: String) throws -> StructuredData {
    let libraryDirectory = ".build/" + buildConfiguration.buildPath
    let moduleName = "Quark"
    var arguments = ["swiftc"]
    arguments += ["--driver-mode=swift"]
    arguments += ["-I", libraryDirectory, "-L", libraryDirectory, "-l\(moduleName)"]

#if os(OSX)
    arguments += ["-target", "x86_64-apple-macosx10.10"]
#endif

    arguments += [configurationFile]

#if Xcode
    // Xcode's PATH doesn't include swiftenv shims. Let's include it mannualy.
    environment["PATH"] = (environment["HOME"] ?? "") + "/.swiftenv/shims:" + (environment["PATH"] ?? "")
#endif

    try system(arguments)

    let file = try File(path: "/tmp/QuarkConfiguration")
    let parser = JSONStructuredDataParser()
    let data = try file.readAllBytes()
    return try parser.parse(data)
}

private func load(commandLineArguments: [String]) throws -> StructuredData {
    var parameters: StructuredData = [:]

    var currentParameter = ""
    var shouldParseParameter = true

    for argument in commandLineArguments {
        if shouldParseParameter {
            if argument.hasPrefix("--") {
                currentParameter = String(Array(argument.characters).suffix(from: 2))
            } else if argument.hasPrefix("-") {
                let flag = String(Array(argument.characters).suffix(from: 1))
                parameters[flag] = true
                continue
            } else {
                throw QuarkError.invalidArgument(description: "\(argument) is a malformed parameter. Parameters should be provided in the format --parameter value.")
            }
            shouldParseParameter = false
        } else { // parse value
            if argument.hasPrefix("--") {
                throw QuarkError.invalidArgument(description: "\(currentParameter) is missing the value. Parameters should be provided in the format --parameter value.")
            }
            parameters[currentParameter] = parse(value: argument)
            shouldParseParameter = true
        }
    }

    if !shouldParseParameter {
        throw QuarkError.invalidArgument(description: "\(currentParameter) is missing the value. Parameters should be provided in the format --parameter value.")
    }

    return parameters
}

private func load(environmentVariables: [String: String]) throws -> StructuredData {
    var variables: StructuredData = [:]

    for (key, value) in environmentVariables {
        let key = convertEnvironmentVariableKeyToCamelCase(key)
        variables[key] = parse(value: value)
    }

    return variables
}

private func parse(value: String) -> StructuredData {
    if isNull(string: value) {
        return .null
    }

    if let intValue = Int(value) {
        return .int(intValue)
    }

    if let doubleValue = Double(value) {
        return .double(doubleValue)
    }

    if let boolValue = convertToBool(string: value) {
        return .bool(boolValue)
    }

    return .string(value)
}

private func isNull(string: String) -> Bool {
    switch string {
    case "null", "NULL", "nil", "NIL":
        return true
    default:
        return false
    }
}

private func convertToBool(string: String) -> Bool? {
    switch string {
    case "True", "true", "yes", "1":
        return true
    case "False", "false", "no", "0":
        return false
    default:
        return nil
    }
}

private func convertEnvironmentVariableKeyToCamelCase(_ variableKey: String) -> String {
    var key = ""
    let words = variableKey.split(separator: "_", omittingEmptySubsequences: false)

    if words[0] == "" {
        key += "_"
    } else {
        key += words[0].lowercased()
    }

    for i in 1 ..< words.count {
        key += words[i].capitalizedWord()
    }

    return key
}

public enum BuildConfiguration {
    case debug
    case release
    case fast

    private static func currentConfiguration(suppressingWarning: Bool) -> BuildConfiguration {
        if suppressingWarning && _isDebugAssertConfiguration() {
            return .debug
        }
        if suppressingWarning && _isFastAssertConfiguration() {
            return .fast
        }
        return .release
    }
}

extension BuildConfiguration {
    var buildPath: String {
        switch self {
        case .debug: return "debug"
        case .release: return "release"
        case .fast: return "release"
        }
    }
}

public var buildConfiguration: BuildConfiguration {
    return BuildConfiguration.currentConfiguration(suppressingWarning: true)
}

// TODO: refactor this

public enum SpawnError : ErrorProtocol {
    case exitStatus(Int32, [String])
}

extension SpawnError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .exitStatus(let code, let args):
            return "exit(\(code)): \(args)"
        }
    }
}

public func system(_ arguments: [String]) throws {
    fflush(stdout)
    do {
        let pid = try spawn(arguments[0], args: arguments)
        let exitStatus = try wait(pid: pid)
        guard exitStatus == 0 else {
            throw SpawnError.exitStatus(exitStatus, arguments)
        }
    } catch let error as SystemError {
        throw error
    }
}

@available(*, unavailable)
public func system() {}

func spawn(_ path: String, args: [String]) throws -> pid_t {
    let argv: [UnsafeMutablePointer<CChar>?] = args.map {
        $0.withCString(strdup)
    }

    defer {
        for case let a? in argv {
            free(a)
        }
    }

    var envs: [String: String] = [:]

#if Xcode
    let keys = ["SWIFT_EXEC", "HOME", "PATH", "TOOLCHAINS", "DEVELOPER_DIR", "LLVM_PROFILE_FILE"]
#else
    let keys = ["SWIFT_EXEC", "HOME", "PATH", "SDKROOT", "TOOLCHAINS", "DEVELOPER_DIR", "LLVM_PROFILE_FILE"]
#endif

    for key in keys {
        if envs[key] == nil {
            envs[key] = environment[key]
        }
    }

    let env: [UnsafeMutablePointer<CChar>?] = envs.map {
        "\($0.0)=\($0.1)".withCString(strdup)
    }

    defer {
        for case let e? in env {
            free(e)
        }
    }

    var pid = pid_t()
    let rv = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], env + [nil])

    if rv != 0 {
        try ensureLastOperationSucceeded()
    }

    return pid
}

func wait(pid: pid_t) throws -> Int32 {
    while true {
        var exitStatus: Int32 = 0
        let rv = waitpid(pid, &exitStatus, 0)

        if rv != -1 {
            if exitStatus & 0x7f == 0 {
                return (exitStatus >> 8) & 0xff
            } else {
                try ensureLastOperationSucceeded()
            }
        } else if errno == EINTR {
            continue
        } else {
            try ensureLastOperationSucceeded()
        }
    }
}
