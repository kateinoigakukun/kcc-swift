func satisfyString<Phase>(predicate: @escaping (Character) -> Bool) -> Parser<Phase, String> where Phase.Collection == String {
    return many(satisfy(predicate: { predicate($0) }))
        .map { String($0) }
}

func stringUntil<Phase>(_ until: [Character]) -> Parser<Phase, String> where Phase.Collection == String {
    return notEmpty(
        satisfyString(predicate: {
            !until.contains($0)
        })
    )
}

struct NotEmptyError: Error {}

func notEmpty<Phase, T: Collection>(_ p: Parser<Phase, T>) -> Parser<Phase, T> {
    return p.map {
        if $0.isEmpty {
            throw NotEmptyError()
        } else {
            return $0
        }
    }
}

func char<Phase>(_ c: Character) -> Parser<Phase, Character> where Phase.Collection == String {
    return satisfy(predicate: { $0 == c })
}

func skipSpaces<Phase>() -> Parser<Phase, Void> where Phase.Collection == String {
    return void <^> many(char(" ") <|> char("\n"))
}

func digit<Phase>() -> Parser<Phase, Character> where Phase.Collection == String {
    return satisfy { "0"..."9" ~= $0 }
}

func number<Phase>() -> Parser<Phase, Int> where Phase.Collection == String {
    return many1(digit()).map { Int(String($0))! }
}

enum TokenError: Error {
    case not(
        String,
        input: ParserInput<String>,
        text: String.SubSequence,
        file: StaticString, function: StaticString, line: Int
    ),
    outOfBounds
}

func token<Phase>(_ string: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) -> Parser<Phase, String> where Phase.Collection == String {
    return Parser { input1 in
        guard let endIndex = input1.collection.index(input1.startIndex, offsetBy: string.count, limitedBy: input1.collection.endIndex) else {
            throw TokenError.outOfBounds
        }
        let prefix = input1.collection[input1.startIndex..<endIndex]
        guard prefix == string else {
            throw TokenError.not(
                string, input: input1,
                text: input1.collection[input1.startIndex...],
                file: file, function: function, line: line
            )
        }
        let newStartIndex = input1.collection.index(input1.startIndex, offsetBy: string.count)
        let input2 = ParserInput(
            previous: input1,
            newIndex: newStartIndex
        )
        return (String(prefix), input2)
    }
}

