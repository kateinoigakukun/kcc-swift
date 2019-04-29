public struct TranslationUnit {
    let externalDecls: [ExternalDeclaration]
}


public enum ExternalDeclaration {
    case functionDefinition(FunctionDefinition)
    case decl(Declaration)
}


public struct FunctionDefinition {
    let declarationSpecifier: [DeclarationSpecifier]
    let declarator: Declarator
    let declaration: [Declaration]
    let compoundStatement: CompoundStatement
}


public struct Declaration {
    let declarationSpecifier: [DeclarationSpecifier]
    let initDeclarator: [InitDeclarator]
}


public enum DeclarationSpecifier: Equatable {
    case storageClassSpecifier(StorageClassSpecifier)
    case typeSpecifier(TypeSpecifier)
    case typeQualifier(TypeQualifier)
}

public struct Declarator: Equatable {
    let pointer: Pointer?
    let directDeclarator: DirectDeclarator
}

public struct CompoundStatement {
    let declaration: [Declaration]
    let statement: [Statement]
}

public enum Statement {
//    case labeled
    case expression(ExpressionStatement)
}

public struct ExpressionStatement {
    let expression: Expression?
}

public enum Expression {
    case assignment(AssignmentExpression)
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
    let declarator: Declarator
    let initializer: Initializer?
}

public enum Initializer {
    case assignment(AssignmentExpression)
    case initializerList([Initializer])
}

public struct Pointer: Equatable {
    let typeQualifier: [TypeQualifier]
    let pointer: Box<Pointer?>
}

class Box<T> {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

extension Box: Equatable where T: Equatable {
    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

indirect public enum DirectDeclarator: Equatable {
    case declarator(Declarator)
    case declaratorWithIdentifiers(DirectDeclarator, [String])
    case identifier(String)
    // TODO
}
