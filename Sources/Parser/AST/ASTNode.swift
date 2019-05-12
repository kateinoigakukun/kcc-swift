public struct TranslationUnit<Phase> {
    public var externalDecls: [ExternalDeclaration<Phase>]
}


public enum ExternalDeclaration<Phase> {
    case functionDefinition(FunctionDefinition<Phase>)
    case decl(Declaration<Phase>)
}


public struct FunctionDefinition<Phase> {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let declarator: Declarator
    public let declaration: [Declaration<Phase>]
    public var compoundStatement: CompoundStatement<Phase>
    public var inputType: [Type]!
    public var outputType: Type!
}


public struct Declaration<Phase> {
    public let declarationSpecifier: [DeclarationSpecifier]
    public let initDeclarator: [InitDeclarator<Phase>]
    public var type: Type!
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

public struct CompoundStatement<Phase> {
    public let declaration: [Declaration<Phase>]
    public var statement: [Statement<Phase>]
}

public indirect enum Statement<Phase> {
//    case labeled
    case compound(CompoundStatement<Phase>)
    case expression(ExpressionStatement<Phase>)
    case jump(JumpStatement<Phase>)
    case selection(SelectionStatement<Phase>)
}

public struct ExpressionStatement<Phase> {
    public var expression: Expression<Phase>?
}

public indirect enum Expression<Phase>: Equatable {
    case assignment(AssignmentExpression<Phase>, Type?)
    case additive(AdditiveExpression<Phase>, Type?)
    case multiplicative(MultiplicativeExpression<Phase>, Type?)
    case unary(UnaryExpression<Phase>, Type?)

    public var type: Type? {
        switch self {
        case .assignment(_, let type),
            .additive(_, let type),
            .multiplicative(_, let type),
            .unary(_, let type): return type
        }
    }
}

public struct AssignmentExpression<Phase>: Equatable {
    public let lvalue: UnaryExpression<Phase>
    public let `operator`: AssignmentOperator
    public var rvalue: Expression<Phase>
}

public indirect enum AdditiveExpression<Phase>: Equatable {
    // TODO: Use multiplicative-expr
    case plus(Expression<Phase>, Expression<Phase>)
    case minus(Expression<Phase>, Expression<Phase>)
}

public indirect enum MultiplicativeExpression<Phase>: Equatable {
    case multiply(Expression<Phase>, Expression<Phase>)
    case divide(Expression<Phase>, Expression<Phase>)
    case modulo(Expression<Phase>, Expression<Phase>)
}

public enum UnaryExpression<Phase>: Equatable {
    case postfix(PostfixExpression<Phase>)
}

indirect public enum PostfixExpression<Phase>: Equatable {
    case primary(PrimaryExpression<Phase>)
    case functionCall(PostfixExpression<Phase>, [Expression<Phase>], Type?)
}

public enum PrimaryExpression<Phase>: Equatable {
    case identifier(String)
    case constant(Constant<Phase>)
    case string(String)
}

public enum Constant<Phase>: Equatable {
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
        default: fatalError()
        }
    }
}

public enum TypeQualifier: String {
    case const, volatile
}

public struct InitDeclarator<Phase> {
    public let declarator: Declarator
    public let initializer: Initializer<Phase>?
}

public enum Initializer<Phase> {
    case expression(Expression<Phase>)
    case initializerList([Initializer<Phase>])
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

public enum JumpStatement<Phase> {
    case `return`(Expression<Phase>?)
}

public struct SelectionStatement<Phase> {
    public let condition: Expression<Phase>
    public let thenStatement: Statement<Phase>
    public let elseStatement: Statement<Phase>?
}
