struct TranslationUnit {
    let externalDecls: [ExternalDeclaration]
}


enum ExternalDeclaration {
    case functionDefinition(FunctionDefinition)
    case decl(Declaration)
}


struct FunctionDefinition {
    let declarationSpecifier: [DeclarationSpecifier]
    let declarator: Declarator
    let declaration: [Declaration]
    let compoundStatement: CompoundStatement
}


struct Declaration {
    let declarationSpecifier: [DeclarationSpecifier]
    let initDeclarator: [InitDeclarator]
}


enum DeclarationSpecifier: Equatable {
    case storageClassSpecifier(StorageClassSpecifier)
    case typeSpecifier(TypeSpecifier)
    case typeQualifier(TypeQualifier)
}

struct Declarator: Equatable {
    let pointer: Pointer?
    let directDeclarator: DirectDeclarator
}

struct CompoundStatement {
    let declaration: [Declaration]
    let statement: [Statement]
}

enum Statement {
//    case labeled
    case expression(ExpressionStatement)
}

struct ExpressionStatement {
    let expression: Expression?
}

enum Expression {
    case assignment(AssignmentExpression)
}

indirect enum AssignmentExpression {
    case conditional(UnaryExpression) // TODO
    case assignment(UnaryExpression, AssignmentOperator, AssignmentExpression)
}

enum UnaryExpression {
    case postfix(PostfixExpression)
}

indirect enum PostfixExpression {
    case primary(PrimaryExpression)
    case functionCall(PostfixExpression, AssignmentExpression)
}

enum PrimaryExpression {
    case identifier(String)
    case constant(Constant)
    case string(String)
}

enum Constant {
    case integer(Int)
}

enum AssignmentOperator {
    case equal // =
}

enum StorageClassSpecifier: String {
    case auto, register, `static`, extern, typedef
}

enum TypeSpecifier: String {
    case char, short, int, long, float, double, signed, unsigned
}

enum TypeQualifier: String {
    case const, volatile
}

struct InitDeclarator {
    let declarator: Declarator
    let initializer: Initializer?
}

enum Initializer {
    case assignment(AssignmentExpression)
    case initializerList([Initializer])
}

struct Pointer: Equatable {
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

indirect enum DirectDeclarator: Equatable {
    case declarator(Declarator)
    case declaratorWithIdentifiers(DirectDeclarator, [String])
    case identifier(String)
    // TODO
}
