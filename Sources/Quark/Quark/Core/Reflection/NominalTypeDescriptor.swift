struct NominalTypeDescriptor : PointerType {
    var pointer: UnsafePointer<_NominalTypeDescriptor>

    var mangledName: String {
        return String(cString: relativePointer(base: pointer, offset: pointer.pointee.mangledName))
    }

    var numberOfFields: Int {
        return Int(pointer.pointee.numberOfFields)
    }

    var fieldOffsetVector: Int {
        return Int(pointer.pointee.fieldOffsetVector)
    }

    var fieldNames: [String] {
        return Array(utf8Strings: relativePointer(base: UnsafePointer<Int32>(self.pointer).advanced(by: 3), offset: self.pointer.pointee.fieldNames))
    }

    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>

    var fieldTypesAccessor: FieldsTypeAccessor? {
        let offset = pointer.pointee.fieldTypesAccessor
        guard offset != 0 else { return nil }
        let offsetPointer: UnsafePointer<Int> = relativePointer(base: UnsafePointer<Int32>(self.pointer).advanced(by: 4), offset: offset)
        return unsafeBitCast(offsetPointer, to: FieldsTypeAccessor.self)
    }
}

struct _NominalTypeDescriptor {
    var mangledName: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
    var fieldNames: Int32
    var fieldTypesAccessor: Int32
}
