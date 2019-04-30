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

public enum Statement {
//    case labeled
    case expression(ExpressionStatement)
}

public struct ExpressionStatement {
    public let expression: Expression?
}

public enum Expression {
    case assignment(AssignmentExpression)
    var assignment: AssignmentExpression? {
        switch self {
        case .assignment(let assignment):
            return assignment
        }
    }


    // TODO: Support only integer argument now
    public var functionCall: (String, Int)? {
        switch self {
        case .assignment(
            .conditional(
                .postfix(
                    .functionCall(
                        .primary(.identifier(let name)),
                        .conditional(.postfix(.primary(.constant(.integer(let arg)))))
                    )
                )
            )
            ):
            return (name, arg)
        default:
            return nil
        }
    }
}

indirect public enum AssignmentExpression {
    case conditional(UnaryExpression) // TODO
    case assignment(UnaryExpression, AssignmentOperator, AssignmentExpression)
}

public enum UnaryExpression {
    case postfix(PostfixExpression)
}

indirect public enum PostfixExpression {
    case primary(PrimaryExpression)
    case functionCall(PostfixExpression, AssignmentExpression)
}

public enum PrimaryExpression {
    case identifier(String)
    case constant(Constant)
    case string(String)
}

public enum Constant {
    case integer(Int)
}

public enum AssignmentOperator {
    case equal // =
}

public enum StorageClassSpecifier: String {
    case auto, register, `static`, extern, typedef
}

public enum TypeSpecifier: String {
    case char, short, int, long, float, double, signed, unsigned
}

public enum TypeQualifier: String {
    case const, volatile
}

public struct InitDeclarator {
    public let declarator: Declarator
    public let initializer: Initializer?
}

public enum Initializer {
    case assignment(AssignmentExpression)
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
    case declaratorWithIdentifiers(DirectDeclarator, [String])
    case identifier(String)
    // TODO
}
