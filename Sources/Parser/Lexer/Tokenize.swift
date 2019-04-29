func lex() -> Lexer<[Token]> {
    return lexToken().flatMap { result -> Lexer<[Token]> in
        switch result {
        case .eof: return .pure([Token.eof])
        default:
            return cons(x: result) <^> (skipWhitespaces() *> lex())
        }
    }
}

func skipWhitespaces() -> Lexer<()> {
    return const(()) <^> satisfyString(predicate: {
        return [" ", "\t" , "\n"].contains($0)
    })
}

func lexToken() -> Lexer<Token> {
    return choice(
        [
            lexOperator(),
            lexString(),
            lexInteger(),
            lexIdentifier(),
            lexEof(),
        ]
    )
}

let singleCharOperators: [Character: Token] = [
    "(" : .leftParen,
    ")" : .rightParen,
    "{" : .leftBrace,
    "}" : .rightBrace,
    "[" : .leftBracket,
    "]" : .rightBracket,
    ";" : .semicolon,
    "," : .comma,
    "=" : .assign,
    ">" : .greaterThan,
    "*" : .multiply,
    "/" : .divide,
    "&" : .and,
    "!" : .not,
    "+" : .plus,
    "-" : .minus,
]

let multiCharOperators: [String: Token] = [
    "!=": .notEqual,
    "==": .equal,
]

func lexOperator() -> Lexer<Token> {
    func mapOperator(_ string: String, _ tk: Token) -> Lexer<Token> {
        return const(tk) <^> token(string)
    }
    return choice(
        singleCharOperators.map { mapOperator(String($0.key), $0.value) }
            + multiCharOperators.map { mapOperator($0.key, $0.value) }
    )
}

func lexString() -> Lexer<Token> {
    let content: Lexer<Token> = Token.string <^> stringUntil(["\""])
    return char("\"") *> content <* char("\"")
}

func lexInteger() -> Lexer<Token> {
    return Token.integer <^> number()
}

func lexIdentifier() -> Lexer<Token> {
    return Token.identifier <^> stringUntil([" ", "\n"] + singleCharOperators.keys)
}

enum EofError: Error { case noMatch }

func lexEof() -> Lexer<Token> {
    return Lexer { input in
        if input.collection.endIndex == input.startIndex {
            return (.eof, input)
        } else {
            throw EofError.noMatch
        }
    }
}
