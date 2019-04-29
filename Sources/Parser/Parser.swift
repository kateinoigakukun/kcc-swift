struct ParserInput<C: Collection> {
    let collection: C
    let startIndex: C.Index

    fileprivate init(collection: C) {
        self.collection = collection
        self.startIndex = collection.startIndex
    }

    static func root(_ collection: C) -> ParserInput<C> {
        return .init(collection: collection)
    }

    init(previous: ParserInput, newIndex: C.Index) {
        self.collection = previous.collection
        self.startIndex = newIndex
    }
}

protocol ParserPhase {
    associatedtype Collection: Swift.Collection
}

struct Parser<Phase: ParserPhase, T> {
    typealias Input = ParserInput<Phase.Collection>
    let parse: (Input) throws -> (T, Input)

    @inline(__always)
    func map<U>(_ transformer: @escaping (T) throws -> U) -> Parser<Phase, U> {
        return Parser<Phase, U> {
            let (result1, tail1) = try self.parse($0)
            return (try transformer(result1), tail1)
        }
    }

    @inline(__always)
    func flatMap<U>(_ transformer: @escaping (T) throws -> Parser<Phase, U>) -> Parser<Phase, U> {
        return Parser<Phase, U> { input1 in
            let (result1, input2) = try self.parse(input1)
            return try transformer(result1).parse(input2)
        }
    }

    @inline(__always)
    static func pure(_ value: T) -> Parser<Phase, T> {
        return Parser<Phase, T> { (value, $0) }
    }

    @inline(__always)
    static func fail(_ error: Error) -> Parser<Phase, T> {
        return Parser<Phase, T> { _ in throw error }
    }
}
