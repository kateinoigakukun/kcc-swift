enum Token: Equatable {
    case leftParen    // (
    case rightParen   // )
    case leftBrace    // {
    case rightBrace   // }
    case leftBracket  // [
    case rightBracket // ]
    case semicolon   // ;
    case comma        //,
    case string(String)
    case char(Character)
    case integer(Int)
    case identifier(String)

    case assign // =
    case greaterThan // >
    case lessThan //<
    case multiply //*
    case divide // /
    case and   // &
    case not // !
    case plus // +
    case minus // -
    case notEqual // !=
    case equal // ==

    case eof
}
