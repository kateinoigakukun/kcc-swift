import Parser

extension Array where Element == DeclarationSpecifier {
    var type: TypeSpecifier? {
        return lazy.compactMap { spec -> TypeSpecifier? in
            switch spec {
            case .typeSpecifier(let specifier):
                return specifier
            default: return nil
            }
        }.first
    }
}

public class TypeChecker {

    public init() {}

    func solve(_ unit: TranslationUnit) -> TranslationUnit {
        var context: DeclContext = [:]
        for decl in unit.externalDecls {
        }
        return unit
    }

    func solve(_ externalDecl: ExternalDeclaration) -> DeclContext {
        var context: DeclContext = [:]
        switch externalDecl {
        case .decl(let decl):
            context.merge(check(decl), uniquingKeysWith: { $1 })
        case .functionDefinition(let functionDefinition):
            context.merge(check(functionDefinition), uniquingKeysWith: { $1 })
        }
        return context
    }

    func check(_ functionDefinition: FunctionDefinition) -> DeclContext {
        var context: DeclContext = [:]
        let output = functionDefinition.declarationSpecifier.type!.asType() // TODO Throw error
        switch functionDefinition.declarator.directDeclarator {
        case .declaratorWithIdentifiers(.identifier(let name), let arguments):
            let inputs = arguments.compactMap { 
                $0.declarationSpecifier.type?.asType()
            }
            context[name] = .function(input: inputs, output: output)
            default: unimplemented()
        }
        return context
    }

    func check(_ decl: Declaration) -> DeclContext {
        var context: DeclContext = [:]
        let type = decl.declarationSpecifier.type?.asType()
        for initDecl in decl.initDeclarator {
            switch initDecl.declarator.directDeclarator {
            case .identifier(let id):
                context[id] = type
                default: unimplemented()
            }
        }
        return context
    }

    func solve(_ expr: Expression, context: DeclContext) -> Type {
        switch expr {
        case .additive, .multiplicative:
            return .int
        case .assignment(let assignment, _):
            return solve(assignment.rvalue, context: context)
        case .unary(let unary, _):
            return solve(unary, context: context)
        }
    }

    func solve(_ unary: UnaryExpression, context: DeclContext) -> Type {
        switch unary {
        case .postfix(let postfix):
            return solve(postfix, context: context)
        }
    }

    func solve(_ postfix: PostfixExpression, context: DeclContext) -> Type {
        switch postfix {
        case .functionCall(let postfixExpr, _):
            switch solve(postfixExpr, context: context) {
            case .function(_, let output):
                return output
            default: unimplemented() // TODO: Throw error
            }
        case .primary(let primary):
            return solve(primary, context: context)
        }
    }

    func solve(_ primary: PrimaryExpression, context: DeclContext) -> Type {
        switch primary {
        case .identifier(let id):
            return context[id]! // TODO: Throw error
        case .constant(let constant):
            return solve(constant)
        case .string:
            return .array(.int)
        }
    }

    func solve(_ constant: Constant) -> Type {
        switch constant {
        case .integer: return .int
        }
    }
}

func unimplemented() -> Never {
    fatalError("unimplemented")
}
