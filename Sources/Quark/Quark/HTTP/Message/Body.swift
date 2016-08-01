extension Body {
    /**
     Converts the body's contents into a `Data` buffer.
     If the body is a receiver or sender type,
     it will be drained.
     */
    public mutating func becomeBuffer(timingOut deadline: Double = .never) throws -> Data {
        switch self {
        case .buffer(let data):
            return data
        case .receiver(let receiver):
            let data = Drain(for: receiver, timingOut: deadline).data
            self = .buffer(data)
            return data
        case .sender(let sender):
            let drain = Drain()
            try sender(drain)
            let data = drain.data

            self = .buffer(data)
            return data
        default:
            throw BodyError.inconvertibleType
        }
    }

    /**
     Converts the body's contents into a `ReceivingStream`
     that can be received in chunks.
     */
    public mutating func becomeReceiver() throws -> ReceivingStream {
        switch self {
        case .receiver(let stream):
            return stream
        case .buffer(let data):
            let stream = Drain(for: data)
            self = .receiver(stream)
            return stream
        case .sender(let sender):
            let stream = Drain()
            try sender(stream)
            self = .receiver(stream)
            return stream
        default:
            throw BodyError.inconvertibleType
        }
    }

    /**
     Converts the body's contents into a closure
     that accepts a `SendingStream`.
     */
    public mutating func becomeSender(timingOut deadline: Double = .never) throws -> ((SendingStream) throws -> Void) {
        switch self {
        case .buffer(let data):
            let closure: ((SendingStream) throws -> Void) = { sender in
                try sender.send(data, timingOut: deadline)
            }
            self = .sender(closure)
            return closure
        case .receiver(let receiver):
            let closure: ((SendingStream) throws -> Void) = { sender in
                let data = Drain(for: receiver, timingOut: deadline).data
                try sender.send(data, timingOut: deadline)
            }
            self = .sender(closure)
            return closure
        case .sender(let sender):
            return sender
        default:
            throw BodyError.inconvertibleType
        }
    }
}

extension Body : Equatable {}

public func == (lhs: Body, rhs: Body) -> Bool {
    switch (lhs, rhs) {
        case let (.buffer(l), .buffer(r)) where l == r: return true
        default: return false
    }
}
