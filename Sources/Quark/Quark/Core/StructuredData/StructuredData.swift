public enum StructuredDataError : ErrorProtocol {
    case incompatibleType
    case valueNotFound
    case notStructuredDataInitializable(Any.Type)
    case notStructuredDataRepresentable(Any.Type)
    case notStructuredDataDictionaryKeyInitializable(Any.Type)
    case notStructuredDataDictionaryKeyRepresentable(Any.Type)
    case cannotInitialize(type: Any.Type, from: Any.Type)
}

// MARK: Parser/Serializer Protocols

public protocol StructuredDataParser {
    func parse(_ data: Data) throws -> StructuredData
}

extension StructuredDataParser {
    public func parse(_ convertible: DataConvertible) throws -> StructuredData {
        return try parse(convertible.data)
    }
}

public protocol StructuredDataSerializer {
    func serialize(_ structuredData: StructuredData) throws -> Data
}

// MARK: Initializers

extension StructuredData {
    public init<T: StructuredDataRepresentable>(_ value: T?) {
        self = value?.structuredData ?? .null
    }

    public init<T: StructuredDataRepresentable>(_ values: [T]?) {
        if let values = values {
            self = .array(values.map({$0.structuredData}))
        } else {
            self = .null
        }
    }

    public init<T: StructuredDataRepresentable>(_ values: [T?]?) {
        if let values = values {
            self = .array(values.map({$0?.structuredData ?? .null}))
        } else {
            self = .null
        }
    }

    public init<T: StructuredDataRepresentable>(_ values: [String: T]?) {
        if let values = values {
            var dictionary: [String: StructuredData] = [:]

            for (key, value) in values.map({($0.key, $0.value.structuredData)}) {
                dictionary[key] = value
            }

            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }

    public init<T: StructuredDataRepresentable>(_ values: [String: T?]?) {
        if let values = values {
            var dictionary: [String: StructuredData] = [:]

            for (key, value) in values.map({($0.key, $0.value?.structuredData ?? .null)}) {
                dictionary[key] = value
            }

            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }
}

// MARK: Type Inference

extension StructuredData {
    public static func infer<T: StructuredDataRepresentable>(_ value: T?) -> StructuredData {
        return StructuredData(value)
    }

    public static func infer<T: StructuredDataRepresentable>(_ values: [T]?) -> StructuredData {
        return StructuredData(values)
    }

    public static func infer<T: StructuredDataRepresentable>(_ values: [T?]?) -> StructuredData {
        return StructuredData(values)
    }

    public static func infer<T: StructuredDataRepresentable>(_ values: [String: T]?) -> StructuredData {
        return StructuredData(values)
    }

    public static func infer<T: StructuredDataRepresentable>(_ values: [String: T?]?) -> StructuredData {
        return StructuredData(values)
    }
}

// MARK: is<Type>

extension StructuredData {
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    public var isBool: Bool {
        if case .bool = self {
            return true
        }
        return false
    }

    public var isDouble: Bool {
        if case .double = self {
            return true
        }
        return false
    }

    public var isInt: Bool {
        if case .int = self {
            return true
        }
        return false
    }

    public var isString: Bool {
        if case .string = self {
            return true
        }
        return false
    }

    public var isData: Bool {
        if case .data = self {
            return true
        }
        return false
    }

    public var isArray: Bool {
        if case .array = self {
            return true
        }
        return false
    }

    public var isDictionary: Bool {
        if case .dictionary = self {
            return true
        }
        return false
    }
}

// MARK: as<type>?

extension StructuredData {
    public var asBool: Bool? {
        return try? get()
    }

    public var asDouble: Double? {
        return try? get()
    }

    public var asInt: Int? {
        return try? get()
    }

    public var asString: String? {
        return try? get()
    }

    public var asData: Data? {
        return try? get()
    }

    public var asArray: [StructuredData]? {
        return try? get()
    }

    public var asDictionary: [String: StructuredData]? {
        return try? get()
    }
}

// MARK: try as<type>()

extension StructuredData {
    public func asBool(converting: Bool = false) throws -> Bool {
        guard converting else {
            return try get()
        }

        switch self {
        case .bool(let value):
            return value

        case .int(let value):
            return value != 0

        case .double(let value):
            return value != 0

        case .string(let value):
            switch value.lowercased() {
            case "true": return true
            case "false": return false
            default: throw StructuredDataError.incompatibleType
            }

        case .data(let value):
            return !value.isEmpty

        case .array(let value):
            return !value.isEmpty

        case .dictionary(let value):
            return !value.isEmpty

        case .null:
            return false
        }
    }

    public func asInt(converting: Bool = false) throws -> Int {
        guard converting else {
            return try get()
        }

        switch self {
        case .bool(let value):
            return value ? 1 : 0

        case .int(let value):
            return value

        case .double(let value):
            return Int(value)

        case .string(let value):
            if let int = Int(value) {
                return int
            }
            throw StructuredDataError.incompatibleType

        case .null:
            return 0

        default:
            throw StructuredDataError.incompatibleType
        }
    }

    public func asDouble(converting: Bool = false) throws -> Double {
        guard converting else {
            return try get()
        }

        switch self {
        case .bool(let value):
            return value ? 1.0 : 0.0

        case .int(let value):
            return Double(value)

        case .double(let value):
            return value

        case .string(let value):
            if let double = Double(value) {
                return double
            }
            throw StructuredDataError.incompatibleType

        case .null:
            return 0

        default:
            throw StructuredDataError.incompatibleType
        }
    }

    public func asString(converting: Bool = false) throws -> String {
        guard converting else {
            return try get()
        }

        switch self {
        case .bool(let value):
            return String(value)

        case .int(let value):
            return String(value)

        case .double(let value):
            return String(value)

        case .string(let value):
            return value

        case .data(let value):
            return String(value)

        case .array:
            throw StructuredDataError.incompatibleType

        case .dictionary:
            throw StructuredDataError.incompatibleType

        case .null:
            return "null"
        }
    }

    public func asData(converting: Bool = false) throws -> Data {
        guard converting else {
            return try get()
        }

        switch self {
        case .bool(let value):
            return value ? [0xff] : [0x00]

        case .string(let value):
            return Data(value)

        case .data(let value):
            return value

        case .null:
            return []

        default:
            throw StructuredDataError.incompatibleType
        }
    }

    public func asArray(converting: Bool = false) throws -> [StructuredData] {
        guard converting else {
            return try get()
        }

        switch self {
        case .array(let value):
            return value

        case .null:
            return []

        default:
            throw StructuredDataError.incompatibleType
        }
    }
    
    public func asDictionary(converting: Bool = false) throws -> [String: StructuredData] {
        guard converting else {
            return try get()
        }
        
        switch self {
        case .dictionary(let value):
            return value
            
        case .null:
            return [:]
            
        default:
            throw StructuredDataError.incompatibleType
        }
    }
}

// MARK: Getters

extension StructuredData {
    public func get<T>() throws -> T {
        switch self {
        case .bool(let value as T): return value
        case .int(let value as T): return value
        case .double(let value as T): return value
        case .string(let value as T): return value
        case .data(let value as T): return value
        case .array(let value as T): return value
        case .dictionary(let value as T): return value
        default: throw StructuredDataError.incompatibleType
        }
    }

    public func get<T>(at index: Int) throws -> T {
        guard let value = self[index] else {
            throw StructuredDataError.valueNotFound
        }
        return try value.get()
    }

    public func get<T>(at key: String) throws -> T {
        guard let value = self[key] else {
            throw StructuredDataError.valueNotFound
        }
        return try value.get()
    }
}

// MARK: Setters

extension StructuredData {
    public mutating func set<T : StructuredDataRepresentable>(value: T?, at index: Int) throws {
        switch self {
        case .array(let array):
            var array = array
            if index >= 0 && index < array.count {
                array[index] = value?.structuredData ?? .null
                self = .array(array)
            }
        default:
            throw StructuredDataError.incompatibleType
        }
    }

    public mutating func set<T : StructuredDataRepresentable>(value: T?, at key: String) throws {
        switch self {
        case .dictionary(let dictionary):
            var dictionary = dictionary
            dictionary[key] = value?.structuredData ?? .null
            self = .dictionary(dictionary)
        default:
            throw StructuredDataError.incompatibleType
        }
    }

    public mutating func removeValue(at key: String) throws {
        switch self {
        case .dictionary(let dictionary):
            var dictionary = dictionary
            dictionary[key] = nil
            self = .dictionary(dictionary)
        default:
            throw StructuredDataError.incompatibleType
        }
    }
}

// MARK: Subscripts

extension StructuredData {
    public subscript(index: Int) -> StructuredData? {
        get {
            guard let array = asArray where array.indices.contains(index) else {
                return nil
            }
            return array[index]
        }

        set(structuredData) {
            if case .array(let array) = self {
                var array = array
                if index >= 0 && index < array.count {
                    array[index] = structuredData ?? .null
                    self = .array(array)
                }
            }
        }
    }

    public subscript(keyPath: String) -> StructuredData? {
        get {
            let keys = keyPath.split(separator: ".")
            var value: StructuredData?

            for key in keys {
                if let v = value {
                    value = v.asDictionary?[key]
                } else {
                    value = self.asDictionary?[key]
                }
            }

            return value
        }

        set(structuredData) {
            if case .dictionary(let dictionary) = self {
                var dictionary = dictionary
                var keys = keyPath.split(separator: ".")
                let first = keys.first!
                keys.removeFirst()

                if keys.isEmpty {
                    if let existingStructuredData = self[first],
                        let newStructuredData = structuredData,
                        case .dictionary(let existingDictionary) = existingStructuredData,
                        case .dictionary(let newDictionary) = newStructuredData {
                        var combinedDictionary: [String: StructuredData] = [:]

                        for (key, value) in existingDictionary {
                            combinedDictionary[key] = value
                        }

                        for (key, value) in newDictionary {
                            combinedDictionary[key] = value
                        }

                        dictionary[first] = .dictionary(combinedDictionary)
                    } else {
                        dictionary[first] = structuredData
                    }
                    self = .dictionary(dictionary)
                } else {
                    var next = self[first] ?? [:]
                    next[keys.joined(separator: ".")] = structuredData
                    self[first] = next
                }
            }
        }
    }
}

// MARK: Equatable

extension StructuredData : Equatable {}

public func == (lhs: StructuredData, rhs: StructuredData) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null): return true
    case let (.int(l), .int(r)) where l == r: return true
    case let (.bool(l), .bool(r)) where l == r: return true
    case let (.string(l), .string(r)) where l == r: return true
    case let (.data(l), .data(r)) where l == r: return true
    case let (.double(l), .double(r)) where l == r: return true
    case let (.array(l), .array(r)) where l == r: return true
    case let (.dictionary(l), .dictionary(r)) where l == r: return true
    default: return false
    }
}

// MARK: Literal Convertibles

extension StructuredData : NilLiteralConvertible {
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension StructuredData : BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension StructuredData : IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension StructuredData : FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension StructuredData : StringLiteralConvertible {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension StructuredData : StringInterpolationConvertible {
    public init(stringInterpolation strings: StructuredData...) {
        self = .string(strings.reduce("") { $0 + $1.asString! })
    }

    public init<T>(stringInterpolationSegment expr: T) {
        self = .string(String(expr))
    }
}

extension StructuredData : ArrayLiteralConvertible {
    public init(arrayLiteral elements: StructuredData...) {
        self = .array(elements)
    }
}

extension StructuredData : DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, StructuredData)...) {
        var dictionary = [String: StructuredData](minimumCapacity: elements.count)

        for (key, value) in elements {
            dictionary[key] = value
        }

        self = .dictionary(dictionary)
    }
}

// MARK: CustomStringConvertible

extension StructuredData : CustomStringConvertible {
    public var description: String {
        let escapeMapping: [Character: String] = [
             "\r": "\\r",
             "\n": "\\n",
             "\t": "\\t",
             "\\": "\\\\",
             "\"": "\\\"",

             "\u{2028}": "\\u2028",
             "\u{2029}": "\\u2029",

             "\r\n": "\\r\\n"
        ]

        func escape(_ source: String) -> String {
            var string = "\""

            for character in source.characters {
                if let escapedSymbol = escapeMapping[character] {
                    string.append(escapedSymbol)
                } else {
                    string.append(character)
                }
            }
            
            string.append("\"")
            return string
        }

        func serialize(data: StructuredData) -> String {
            switch data {
            case .null: return "null"
            case .bool(let bool): return String(bool)
            case .double(let number): return String(number)
            case .int(let number): return String(number)
            case .string(let string): return escape(string)
            case .data(let data): return "0x" + data.hexadecimalString()
            case .array(let array): return serialize(array: array)
            case .dictionary(let dictionary): return serialize(dictionary: dictionary)
            }
        }

        func serialize(array: [StructuredData]) -> String {
            var string = "["

            for index in 0 ..< array.count {
                string += serialize(data: array[index])

                if index != array.count - 1 {
                    string += ","
                }
            }

            return string + "]"
        }

        func serialize(dictionary: [String: StructuredData]) -> String {
            var string = "{"
            var index = 0

            for (key, value) in dictionary.sorted(isOrderedBefore: {$0.0 < $1.0}) {
                string += escape(key) + ":" + serialize(data: value)

                if index != dictionary.count - 1 {
                    string += ","
                }

                index += 1
            }

            return string + "}"
        }

        return serialize(data: self)
    }
}
