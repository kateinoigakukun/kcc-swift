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

    var context: DeclContext = [:]
    let unit: TranslationUnit

    public init(unit: TranslationUnit) {
        self.unit = unit
        self.context = makeContext(unit)
    }

    func check() -> TranslationUnit {
        var unit = self.unit
        unit.externalDecls = unit.externalDecls.map {
            self.check($0)
        }
        return unit
    }

    func check(_ externalDecl: ExternalDeclaration) -> ExternalDeclaration {
        switch externalDecl {
        case .functionDefinition(let functionDefinition):
            return .functionDefinition(check(functionDefinition))
        case .decl: unimplemented()
        }
    }

    func check(_ functionDefinition: FunctionDefinition) -> FunctionDefinition {
        let previousContext = self.context
        defer { self.context = previousContext }
        var functionDefinition = functionDefinition
        switch functionDefinition.declarator.directDeclarator {
        case .declaratorWithIdentifiers(.identifier(let name), let arguments):
            guard case let .some(.function(input, output)) = context[name] else {
                unimplemented()
            }
            functionDefinition.inputType = input
            functionDefinition.outputType = output
            for argument in arguments {
                guard case let .identifier(id) = argument.declarator.directDeclarator else {
                    unimplemented()
                }
                context[id] = argument.declarationSpecifier.type?.asType()
            }
        default: unimplemented()
        }
        let compound = check(functionDefinition.compoundStatement)
        functionDefinition.compoundStatement = compound
        return functionDefinition
    }

    func check(_ compoundStatement: CompoundStatement) -> CompoundStatement {
        let previousContext = self.context
        defer { self.context = previousContext }
        self.context = compoundStatement.declaration.reduce(into: context) {
            $0.merge(self.makeContext($1), uniquingKeysWith: { $1 })
        }
        let statements = compoundStatement.statement.map { stmt -> Statement in
            switch stmt {
            case .expression(let exprStatement):
                return .expression(check(exprStatement))
            case .compound(let compoundStatement):
                return .compound(check(compoundStatement))
            case .jump: unimplemented()
            case .selection: unimplemented()
            }
        }
        var compound = compoundStatement
        compound.statement = statements
        return compound
    }

    func makeContext(_ unit: TranslationUnit) -> DeclContext {
        var context: DeclContext = [:]
        for decl in unit.externalDecls {
            context.merge(makeContext(decl), uniquingKeysWith: { $1 })
        }
        return context
    }

    func makeContext(_ externalDecl: ExternalDeclaration) -> DeclContext {
        var context: DeclContext = [:]
        switch externalDecl {
        case .decl(let decl):
            context.merge(makeContext(decl), uniquingKeysWith: { $1 })
        case .functionDefinition(let functionDefinition):
            context.merge(makeContext(functionDefinition), uniquingKeysWith: { $1 })
        }
        return context
    }

    func makeContext(_ functionDefinition: FunctionDefinition) -> DeclContext {
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

    func makeContext(_ decl: Declaration) -> DeclContext {
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

    func check(_ exprStatement: ExpressionStatement) -> ExpressionStatement {
        guard let expr = exprStatement.expression else { return exprStatement }
        var exprStatement = exprStatement
        exprStatement.expression = check(expr)
        return exprStatement
    }

    func check(_ expr: AdditiveExpression) -> AdditiveExpression {
        switch expr {
        case let .minus(expr1, expr2):
            return .minus(check(expr1), check(expr2))
        case let .plus(expr1, expr2):
            return .plus(check(expr1), check(expr2))
        }
    }

    func check(_ expr: MultiplicativeExpression) -> MultiplicativeExpression {
        switch expr {
        case let .divide(expr1, expr2):
            return .divide(check(expr1), check(expr2))
        case let .multiply(expr1, expr2):
            return .multiply(check(expr1), check(expr2))
        case let .modulo(expr1, expr2):
            return .modulo(check(expr1), check(expr2))
        }
    }
    func check(_ expr: Expression) -> Expression {
        switch expr {
        case .additive(let additiveExpr, _):
            return .additive(check(additiveExpr), .int)
        case .multiplicative(let multiplicativeExpr, _):
            return .multiplicative(check(multiplicativeExpr), .int)
        case .assignment(var assignment, _):
            switch assignment.lvalue {
            case .postfix(.primary(.identifier(let id))):
                let rvalue = check(assignment.rvalue)
                context[id] = rvalue.type!
                assignment.rvalue = rvalue
                return .assignment(assignment, rvalue.type!)
            default: unimplemented()
            }
        case .unary(let unary, _):
            unimplemented()
        }
    }

    func check(_ unary: UnaryExpression) -> UnaryExpression {
        switch unary {
        case .postfix(let postfix):
            return .postfix(check(postfix))
        }
    }

    func check(_ postfix: PostfixExpression) -> PostfixExpression {
        switch postfix {
        case .functionCall(let postfixExpr, let arguments, _):
            let postfix = check(postfixExpr)
            switch check(postfixExpr) {
            case .function(let input, let output, _):
                for argument in arguments {
                }
                return .functionCall(PostfixExpression, [Expression])
            default: unimplemented() // TODO: Throw error
            }
        case .primary(let primary):
            return solve(primary)
        }
    }

    func solve(_ primary: PrimaryExpression) -> Type {
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

func unimplemented(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("unimplemented", file: file, line: line)
}
