public struct TranslationUnit {
    public var externalDecls: [ExternalDeclaration]
}


public enum ExternalDeclaration {
    case functionDefinition(FunctionDefinition)
    case decl(Declaration)
}


public struct FunctionDefinition {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let declarator: Declarator
//    public let declaration: [Declaration]
    public var compoundStatement: CompoundStatement
    public var inputType: [Type]?
    public var outputType: Type?
}


public struct Declaration {
    public let declarationSpecifier: [DeclarationSpecifier]
    public var initDeclarator: [InitDeclarator]
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
    public var declaration: [Declaration]
    public var statement: [Statement]
}

public indirect enum Statement {
//    case labeled
    case compound(CompoundStatement)
    case expression(ExpressionStatement)
    case jump(JumpStatement)
    case selection(SelectionStatement)
}

public struct ExpressionStatement {
    public var expression: Expression?
}

public indirect enum Expression: Equatable {
    case assignment(AssignmentExpression)
    case additive(AdditiveExpression)
    case multiplicative(MultiplicativeExpression)
    case unary(UnaryExpression)
    case postfix(PostfixExpression)
    case primary(PrimaryExpression)
    case functionCall(FunctionCallExpression)

    public var type: Type? {
        switch self {
        case .additive(let additive):
            return additive.type
        case .multiplicative(let multiplicative):
            return multiplicative.type
        case .assignment(let assignment):
            return assignment.type
        case .unary(let unary):
            return unary.type
        case .primary(let primary):
            return primary.type
        case .functionCall(let functionCall):
            return functionCall.type
        }
    }
}

public struct FunctionCallExpression: Equatable {
    public var name: Expression
    public var argumentList: [Expression]
    public var type: Type?

    public init(name: Expression, argumentList: [Expression], type: Type?) {
        self.name = name
        self.argumentList = argumentList
        self.type = type
    }
}

public struct AssignmentExpression: Equatable {
    public let lvalue: Expression
    public let `operator`: AssignmentOperator
    public var rvalue: Expression

    var type: Type? {
        return rvalue.type
    }
}

public enum AdditiveExpression: Equatable {
    // TODO: Use multiplicative-expr
    case plus(Expression, Expression, Type?)
    case minus(Expression, Expression, Type?)

    var type: Type? {
        switch self {
        case .plus(_, _, let type),
             .minus(_, _, let type):
            return type
        }
    }
}

public enum MultiplicativeExpression: Equatable {
    case multiply(Expression, Expression, Type?)
    case divide(Expression, Expression, Type?)
    case modulo(Expression, Expression, Type?)

    var type: Type? {
        switch self {
        case .multiply(_, _, let type),
             .divide(_, _, let type),
             .modulo(_, _, let type):
            return type
        }
    }
}

public struct UnaryExpression: Equatable {
    public let `operator`: UnaryOperator
    public var expression: Expression // TODO use cast-expression
    var type: Type? {
        switch `operator` {
        case .and:
            return expression.type.map(Type.pointer)
        case .star:
            return expression.type
        }
    }
}

public enum UnaryOperator {
    case and
    case star
}

public enum PostfixExpression: Equatable {}

public enum PrimaryExpression: Equatable {
    case identifier(String, Type?)
    case constant(Constant, Type?)
    case string(String, Type?)
    public var type: Type? {
        switch self {
        case .identifier(_, let type),
             .constant(_, let type),
             .string(_, let type):
            return type
        }
    }
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

    public func asType() -> Type {
        switch self {
        case .int: return .int
        case .void: return .void
        default: fatalError()
        }
    }
}

public enum TypeQualifier: String {
    case const, volatile
}

public struct InitDeclarator {
    public var declarator: Declarator
    public var initializer: Initializer?
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
    case function(DirectDeclarator, ParameterTypeList)
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

public struct SelectionStatement {
    public var condition: Expression
    public var thenStatement: Statement
    public var elseStatement: Statement?
}
