enum ChoiceError: Error { case noMatch }

func choice<Phase, T>(_ ps: [Parser<Phase, T>]) -> Parser<Phase, T> {
    return Parser { content in
        for p in ps {
            guard let r = try? p.parse(content) else { continue }
            return r
        }
        throw ChoiceError.noMatch
    }
}

func many<Phase, T>(_ p: Parser<Phase, T>, function: StaticString = #function) -> Parser<Phase, [T]> {
    return many1(p, function: function) <|> Parser.pure([])
}

func many1<Phase, T>(_ p: Parser<Phase, T>, function: StaticString = #function) -> Parser<Phase, [T]> {
    //    Notes: Beautiful impl but slow
    return Parser<Phase, [T]> { content in
        let r_1 = try p.parse(content)
        var list: [T] = [r_1.0]
        var tail = r_1.1
        while let r_n = try? p.parse(tail) {
            tail = r_n.1
            list.append(r_n.0)
        }
        return (list, tail)
    }
}

enum SatisfyError<C: Collection>: Error {
    case invalid(head: C.Element, input: ParserInput<C>), empty
}

func satisfy<Phase>(predicate: @escaping (Phase.Collection.Element) -> Bool) -> Parser<Phase, Phase.Collection.Element> {
    return Parser { input in
        guard input.startIndex != input.collection.endIndex  else {
            throw SatisfyError<Phase.Collection>.empty
        }

        let head = input.collection[input.startIndex]
        let index1 = input.collection.index(after: input.startIndex)
        let newInput = ParserInput(previous: input, newIndex: index1)
        guard predicate(head) else {
            throw SatisfyError<Phase.Collection>.invalid(head: head, input: input)
        }
        return (head, newInput)
    }
}

func orNil<Phase, T>(_ p: Parser<Phase, T>) -> Parser<Phase, T?> {
    return (Optional.some <^> p) <|> .pure(nil)
}
