enum LexerPhase: ParserPhase {
    typealias Collection = String
}
typealias Lexer<T> = Parser<LexerPhase, T>
