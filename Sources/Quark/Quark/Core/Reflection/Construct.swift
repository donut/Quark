public protocol Initializable : class {
    init()
}

/// Create a class or struct with a constructor method. Return a value of `property.type` for each property. Classes must conform to `Initializable`.
public func construct<T>(_ type: T.Type = T.self, constructor: (Property.Description) throws -> Any) throws -> T {
    guard Metadata(type: T.self).isStructOrClass else { throw ReflectionError.notStructOrClass(type: T.self) }
    if Metadata(type: T.self)?.kind == .struct {
        return try constructValueType(constructor)
    } else if let initializable = T.self as? Initializable.Type, value = initializable.init() as? T {
        return try constructReferenceType(value, constructor: constructor)
    } else {
        throw ReflectionError.classNotInitializable(type: T.self)
    }
}

private func constructValueType<T>(_ constructor: (Property.Description) throws -> Any) throws -> T {
    guard Metadata(type: T.self)?.kind == .struct else { throw ReflectionError.notStructOrClass(type: T.self) }
    let pointer = UnsafeMutablePointer<T>(allocatingCapacity: 1)
    defer { pointer.deallocateCapacity(1) }
    var storage = UnsafeMutablePointer<Int>(pointer)
    var values = [Any]()
    try constructType(storage: &storage, values: &values, properties: properties(T.self), constructor: constructor)
    return pointer.pointee
}

private func constructReferenceType<T>(_ value: T, constructor: (Property.Description) throws -> Any) throws -> T {
    var copy = value
    var storage = mutableStorageForInstance(&copy)
    var values = [Any]()
    try constructType(storage: &storage, values: &values, properties: properties(T.self), constructor: constructor)
    return copy
}

private func constructType(storage: inout UnsafeMutablePointer<Int>, values: inout [Any], properties: [Property.Description], constructor: (Property.Description) throws -> Any) throws {
    for property in properties {
        var v = try constructor(property)
        guard value(v, is: property.type) else { throw ReflectionError.valueIsNotType(value: v, type: property.type) }
        values.append(v)
        storage.consumeBuffer(bufferForInstance(&v))
    }
}

/// Create a class or struct from a dictionary. Classes must conform to `Initializable`.
public func construct<T>(_ type: T.Type = T.self, dictionary: [String: Any]) throws -> T {
    return try construct(constructor: constructorForDictionary(dictionary))
}

private func constructorForDictionary(_ dictionary: [String: Any]) -> (Property.Description) throws -> Any {
    return { property in
        if let value = dictionary[property.key] {
            return value
        } else if let nilLiteralConvertible = property.type as? NilLiteralConvertible.Type {
            return nilLiteralConvertible.init(nilLiteral: ())
        } else {
            throw ReflectionError.requiredValueMissing(key: property.key)
        }
    }
}
