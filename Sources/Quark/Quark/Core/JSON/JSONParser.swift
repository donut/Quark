// This file has been modified from its original project Swift-JsonSerializer

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum JSONParseError : ErrorProtocol, CustomStringConvertible {
    case unexpectedTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case insufficientTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case extraTokenError(reason: String, lineNumber: Int, columnNumber: Int)
    case nonStringKeyError(reason: String, lineNumber: Int, columnNumber: Int)
    case invalidStringError(reason: String, lineNumber: Int, columnNumber: Int)
    case invalidNumberError(reason: String, lineNumber: Int, columnNumber: Int)

    public var description: String {
        switch self {
        case unexpectedTokenError(let r, let l, let c):
            return "UnexpectedTokenError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        case insufficientTokenError(let r, let l, let c):
            return "InsufficientTokenError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        case extraTokenError(let r, let l, let c):
            return "ExtraTokenError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        case nonStringKeyError(let r, let l, let c):
            return "NonStringKeyError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        case invalidStringError(let r, let l, let c):
            return "InvalidStringError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        case invalidNumberError(let r, let l, let c):
            return "InvalidNumberError!\nLine: \(l)\nColumn: \(c)]\nReason: \(r)"
        }
    }
}

public struct JSONParser {
    public init() {}

    public func parse(data: Data) throws -> JSON {
        return try GenericJSONParser(data).parse()
    }
}

class GenericJSONParser<ByteSequence : Collection where ByteSequence.Iterator.Element == UInt8> {
    typealias Source = ByteSequence
    typealias Char = Source.Iterator.Element

    let source: Source
    var cur: Source.Index
    let end: Source.Index

    var lineNumber = 1
    var columnNumber = 1

    init(_ source: Source) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }

    func parse() throws -> JSON {
        let JSON = try parseValue()
        skipWhitespaces()
        if (cur == end) {
            return JSON
        } else {
            throw JSONParseError.extraTokenError(
                reason: "extra tokens found",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
    }
}

// MARK: - Private

extension GenericJSONParser {
    private func parseValue() throws -> JSON {
        skipWhitespaces()
        if cur == end {
            throw JSONParseError.insufficientTokenError(
                reason: "unexpected end of tokens",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }

        switch currentChar {
        case Char(ascii: "n"): return try parseSymbol("null", JSON.nullValue)
        case Char(ascii: "t"): return try parseSymbol("true", JSON.booleanValue(true))
        case Char(ascii: "f"): return try parseSymbol("false", JSON.booleanValue(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"): return try parseNumber()
        case Char(ascii: "\""): return try parseString()
        case Char(ascii: "{"): return try parseObject()
        case Char(ascii: "["): return try parseArray()
        case (let c): throw JSONParseError.unexpectedTokenError(
            reason: "unexpected token: \(c)",
            lineNumber: lineNumber,
            columnNumber: columnNumber
        )
        }
    }

    private var currentChar: Char {
        return source[cur]
    }

    private var nextChar: Char {
        return source[source.index(after: cur)]
    }

    private var currentSymbol: Character {
        return Character(UnicodeScalar(currentChar))
    }

    private func parseSymbol(_ target: StaticString, _ iftrue: @autoclosure (Void) -> JSON) throws -> JSON {
        if expect(target) {
            return iftrue()
        } else {
            throw JSONParseError.unexpectedTokenError(
                reason: "expected \"\(target)\" but \(currentSymbol)",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
    }

    private func parseString() throws -> JSON {
        assert(currentChar == Char(ascii: "\""), "points a double quote")
        advance()
        var buffer: [CChar] = []

        LOOP: while cur != end {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()
                if (cur == end) {
                    throw JSONParseError.invalidStringError(
                        reason: "unexpected end of a string literal",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }

                if let c = parseEscapedChar() {
                    for u in String(c).utf8 {
                        buffer.append(CChar(bitPattern: u))
                    }
                } else {
                    throw JSONParseError.invalidStringError(
                        reason: "invalid escape sequence",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
            case Char(ascii: "\""): break LOOP
            default: buffer.append(CChar(bitPattern: currentChar))
            }
            advance()
        }

        if !expect("\"") {
            throw JSONParseError.invalidStringError(
                reason: "missing double quote",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }

        buffer.append(0)
        let s = String(validatingUTF8: buffer)!
        return .stringValue(s)
    }

    private func parseEscapedChar() -> UnicodeScalar? {
        let c = UnicodeScalar(currentChar)

        if c == "u" {
            var length = 0
            var value: UInt32 = 0

            while let d = hexToDigit(nextChar) {
                advance()
                length += 1

                if length > 8 {
                    break
                }

                value = (value << 4) | d
            }

            if length < 2 {
                return nil
            }

            return UnicodeScalar(value)
        } else {
            let c = UnicodeScalar(currentChar)
            return unescapeMapping[c] ?? c
        }
    }

    private func parseNumber() throws -> JSON {
        let sign = expect("-") ? -1.0 : 1.0
        var integer: Int64 = 0

        switch currentChar {
        case Char(ascii: "0"): advance()
        case Char(ascii: "1") ... Char(ascii: "9"):
            while cur != end {
                if let value = digitToInt(currentChar) {
                    integer = (integer * 10) + Int64(value)
                } else {
                    break
                }
                advance()
            }
        default:
            throw JSONParseError.invalidStringError(
                reason: "missing double quote",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }

        if integer != Int64(Double(integer)) {
            throw JSONParseError.invalidNumberError(
                reason: "too large number",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }

        var fraction: Double = 0.0

        if expect(".") {
            var factor = 0.1
            var fractionLength = 0

            while cur != end {
                if let value = digitToInt(currentChar) {
                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength += 1
                } else {
                    break
                }
                advance()
            }

            if fractionLength == 0 {
                throw JSONParseError.invalidNumberError(
                    reason: "insufficient fraction part in number",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }

        var exponent: Int64 = 0

        if expect("e") || expect("E") {
            var expSign: Int64 = 1

            if expect("-") {
                expSign = -1
            } else if expect("+") {}

            exponent = 0
            var exponentLength = 0

            while cur != end {
                if let value = digitToInt(currentChar) {
                    exponent = (exponent * 10) + Int64(value)
                    exponentLength += 1
                } else {
                    break
                }
                advance()
            }

            if exponentLength == 0 {
                throw JSONParseError.invalidNumberError(
                    reason: "insufficient exponent part in number",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }

            exponent *= expSign
        }

        return .numberValue(sign * (Double(integer) + fraction) * pow(10, Double(exponent)))
    }

    private func parseObject() throws -> JSON {
        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        advance()
        skipWhitespaces()
        var object: [String: JSON] = [:]

        LOOP: while cur != end && !expect("}") {
            let keyValue = try parseValue()

            switch keyValue {
            case .stringValue(let key):
                skipWhitespaces()

                if !expect(":") {
                    throw JSONParseError.unexpectedTokenError(
                        reason: "missing colon (:)",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }

                skipWhitespaces()
                let value = try parseValue()
                object[key] = value
                skipWhitespaces()

                if expect(",") {
                    break
                } else if expect("}") {
                    break LOOP
                } else {
                    throw JSONParseError.unexpectedTokenError(
                        reason: "missing comma (,)",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
            default:
                throw JSONParseError.nonStringKeyError(
                    reason: "unexpected value for object key",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }

        return .objectValue(object)
    }

    private func parseArray() throws -> JSON {
        assert(currentChar == Char(ascii: "["), "points \"[\"")
        advance()
        skipWhitespaces()

        var array: [JSON] = []

        LOOP: while cur != end && !expect("]") {
            let JSON = try parseValue()
            skipWhitespaces()
            array.append(JSON)

            if expect(",") {
                continue
            } else if expect("]") {
                break LOOP
            } else {
                throw JSONParseError.unexpectedTokenError(
                    reason: "missing comma (,) (token: \(currentSymbol))",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }

        return .arrayValue(array)
    }


    private func expect(_ target: StaticString) -> Bool {
        if cur == end {
            return false
        }

        if !isIdentifier(target.utf8Start.pointee) {
            if target.utf8Start.pointee == currentChar {
                advance()
                return true
            } else {
                return false
            }
        }

        let start = cur
        let l = lineNumber
        let c = columnNumber

        var p = target.utf8Start
        let endp = p.advanced(by: Int(target.utf8CodeUnitCount))

        while p != endp {
            if p.pointee != currentChar {
                cur = start
                lineNumber = l
                columnNumber = c
                return false
            }
            p += 1
            advance()
        }

        return true
    }

    // only "true", "false", "null" are identifiers
    private func isIdentifier(_ char: Char) -> Bool {
        switch char {
        case Char(ascii: "a") ... Char(ascii: "z"):
            return true
        default:
            return false
        }
    }

    private func advance() {
        assert(cur != end, "out of range")
        cur = source.index(after: cur)

        if cur != end {
            switch currentChar {

            case Char(ascii: "\n"):
                lineNumber += 1
                columnNumber = 1

            default:
                columnNumber += 1
            }
        }
    }

    private func skipWhitespaces() {
        while cur != end {
            switch currentChar {
            case Char(ascii: " "), Char(ascii: "\t"), Char(ascii: "\r"), Char(ascii: "\n"):
                break
            default:
                return
            }
            advance()
        }
    }
}

let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [
    "t": "\t",
    "r": "\r",
    "n": "\n"
]

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

let hexMapping: [UnicodeScalar: UInt32] = [
    "0": 0x0,
    "1": 0x1,
    "2": 0x2,
    "3": 0x3,
    "4": 0x4,
    "5": 0x5,
    "6": 0x6,
    "7": 0x7,
    "8": 0x8,
    "9": 0x9,
    "a": 0xA, "A": 0xA,
    "b": 0xB, "B": 0xB,
    "c": 0xC, "C": 0xC,
    "d": 0xD, "D": 0xD,
    "e": 0xE, "E": 0xE,
    "f": 0xF, "F": 0xF
]

let digitMapping: [UnicodeScalar:Int] = [
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9
]

public func escapeAsJSON(_ source : String) -> String {
    var s = "\""

    for c in source.characters {
        if let escapedSymbol = escapeMapping[c] {
            s.append(escapedSymbol)
        } else {
            s.append(c)
        }
    }

    s.append("\"")

    return s
}

func digitToInt(_ byte: UInt8) -> Int? {
    return digitMapping[UnicodeScalar(byte)]
}

func hexToDigit(_ byte: UInt8) -> UInt32? {
    return hexMapping[UnicodeScalar(byte)]
}
