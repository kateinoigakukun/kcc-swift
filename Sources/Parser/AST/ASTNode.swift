public struct TranslationUnit {
    public let externalDecls: [ExternalDeclaration]
}


public enum ExternalDeclaration {
    case functionDefinition(FunctionDefinition)
    case decl(Declaration)
}


public struct FunctionDefinition {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let declarator: Declarator
    public let declaration: [Declaration]
    public let compoundStatement: CompoundStatement
}


public struct Declaration {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let initDeclarator: [InitDeclarator]
}


public enum DeclarationSpecifier: Equatable {
    case storageClassSpecifier(StorageClassSpecifier)
    case typeSpecifier(TypeSpecifier)
    case typeQualifier(TypeQualifier)
}

public struct Declarator: Equatable {
    public let pointer: Pointer?
    public let directDeclarator: DirectDeclarator
}

public struct CompoundStatement {
    public let declaration: [Declaration]
    public let statement: [Statement]
}

public indirect enum Statement {
//    case labeled
    case compound(CompoundStatement)
    case expression(ExpressionStatement)
    case jump(JumpStatement)
    case selection(SelectionStatement)
}

public struct ExpressionStatement {
    public let expression: Expression?
}

public indirect enum Expression: Equatable {
    case assignment(AssignmentExpression)
    case additive(AdditiveExpression)
    case multiplicative(MultiplicativeExpression)
    case unary(UnaryExpression)
}

public struct AssignmentExpression: Equatable {
    let lvalue: UnaryExpression
    let `operator`: AssignmentOperator
    let rvalue: Expression
}

public indirect enum AdditiveExpression: Equatable {
    // TODO: Use multiplicative-expr
    case plus(Expression, Expression)
    case minus(Expression, Expression)
}

public indirect enum MultiplicativeExpression: Equatable {
    case multiply(Expression, Expression)
    case divide(Expression, Expression)
    case modulo(Expression, Expression)
}

public enum UnaryExpression: Equatable {
    case postfix(PostfixExpression)
}

indirect public enum PostfixExpression: Equatable {
    case primary(PrimaryExpression)
    case functionCall(PostfixExpression, [Expression])
}

public enum PrimaryExpression: Equatable {
    case identifier(String)
    case constant(Constant)
    case string(String)
}

public enum Constant: Equatable {
    case integer(Int)
}

public enum AssignmentOperator {
    case equal // =
}

public enum StorageClassSpecifier: String {
    case auto, register, `static`, extern, typedef
}

public enum TypeSpecifier: String {
    case char, short, int, long, float, double, signed, unsigned, void
}

public enum TypeQualifier: String {
    case const, volatile
}

public struct InitDeclarator {
    public let declarator: Declarator
    public let initializer: Initializer?
}

public enum Initializer {
    case expression(Expression)
    case initializerList([Initializer])
}

public struct Pointer: Equatable {
    public let typeQualifier: [TypeQualifier]
    public let pointer: Box<Pointer?>
}

public class Box<T> {
    public let value: T
    init(_ value: T) {
        self.value = value
    }
}

extension Box: Equatable where T: Equatable {
    public static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

indirect public enum DirectDeclarator: Equatable {
    case declarator(Declarator)
    case declaratorWithIdentifiers(DirectDeclarator, ParameterTypeList)
    case identifier(String)
    // TODO
}

public enum ParameterTypeList: Equatable, Sequence {
    case variadic(ParameterList)
    case `default`(ParameterList)

    public typealias Iterator = ParameterList.Iterator
    public __consuming func makeIterator() -> ParameterList.Iterator {
        switch self {
        case .default(let list), .variadic(let list):
            return list.makeIterator()
        }
    }
}

public typealias ParameterList = [ParameterDeclaration]

public struct ParameterDeclaration: Equatable {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let declarator: Declarator
}

public enum JumpStatement {
    case `return`(Expression?)
}

public indirect enum SelectionStatement {
    case `if`(Expression, Statement, Statement?)
}
