precedencegroup MonadicPrecedenceLeft {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

precedencegroup AlternativePrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

precedencegroup ApplicativePrecedence {
    associativity: left
    higherThan: AlternativePrecedence
    lowerThan: NilCoalescingPrecedence
}

precedencegroup ApplicativeSequencePrecedence {
    associativity: left
    higherThan: ApplicativePrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator <^> : ApplicativePrecedence
infix operator <*> : ApplicativePrecedence
infix operator <* : ApplicativeSequencePrecedence
infix operator *> : ApplicativeSequencePrecedence
infix operator <|> : AlternativePrecedence
infix operator >>- : MonadicPrecedenceLeft

@inline(__always)
func <|> <Phase, T>(a: Parser<Phase, T>, b: @autoclosure @escaping () -> Parser<Phase, T>) -> Parser<Phase, T> {
    return Parser { input in
        do {
            return try a.parse(input)
        } catch {
            return try b().parse(input)
        }
    }
}

import Foundation

@inline(__always)
func <*> <Phase, A, B>(a: Parser<Phase, (A) -> B>, b: @autoclosure @escaping () -> Parser<Phase, A>) -> Parser<Phase, B> {
    //    return a.flatMap { f in b().map { f($0) } }
    return Parser<Phase, B> { content in
        let (f, tailA) = try a.parse(content)
        let (arg, tailB) = try b().parse(tailA)
        return (f(arg), tailB)
    }
}

@inline(__always)
func <^> <Phase, A, B>(f: @escaping (A) -> B, p: @autoclosure @escaping () -> Parser<Phase, A>) -> Parser<Phase, B> {
    return Parser { content in
        let (a, tailA) = try p().parse(content)
        return (f(a), tailA)
    }
}

@inline(__always)
func >>- <Phase, A, B>(p: Parser<Phase, A>, f: @escaping (A) -> Parser<Phase, B>) -> Parser<Phase, B> {
    return p.flatMap(f)
}

@inline(__always)
func *> <Phase, A, B>(a: Parser<Phase, A>, b: Parser<Phase, B>) -> Parser<Phase, B> {
    //    return const(id) <^> a <*> b
    return Parser<Phase, B> { content in
        let (_, tailA) = try a.parse(content)
        return try b.parse(tailA)
    }
}

@inline(__always)
func <* <Phase, A, B>(a: Parser<Phase, A>, b: Parser<Phase, B>) -> Parser<Phase, A> {
    //    return const <^> a <*> b
    return Parser<Phase, A> { content in
        let (resultA, tailA) = try a.parse(content)
        let (_, tailB) = try b.parse(tailA)
        return (resultA, tailB)
    }
}
