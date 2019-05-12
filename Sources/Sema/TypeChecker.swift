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
    var currentFunc: FunctionDefinition?
    let unit: TranslationUnit

    public init(unit: TranslationUnit) {
        self.unit = unit
        self.context = TypeChecker.builtin()
            .merging(makeContext(unit), uniquingKeysWith: { $1 })
    }

    static func builtin() -> DeclContext {
        return [
            "print_char": .function(input: [.int], output: .void)
        ]
    }

    public func check() -> TranslationUnit {
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
        case .function(.identifier(let name), let arguments):
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
        currentFunc = functionDefinition
        let compound = check(functionDefinition.compoundStatement)
        functionDefinition.compoundStatement = compound
        return functionDefinition
    }

    func check(_ statement: Statement) -> Statement {
        switch statement {
        case .expression(let exprStatement):
            return .expression(check(exprStatement))
        case .compound(let compoundStatement):
            return .compound(check(compoundStatement))
        case .jump(let jump):
            return .jump(check(jump))
        case .selection(let selection):
            return .selection(check(selection))
        }
    }

    func check(_ compoundStatement: CompoundStatement) -> CompoundStatement {
        let previousContext = self.context
        defer { self.context = previousContext }
        self.context = compoundStatement.declaration.reduce(into: context) {
            $0.merge(self.makeContext($1), uniquingKeysWith: { $1 })
        }
        let statements = compoundStatement.statement.map(check)
        var compound = compoundStatement
        compound.statement = statements
        return compound
    }

    func check(_ jump: JumpStatement) -> JumpStatement {
        switch jump {
        case .return(.some(let expr)):
            guard let function = currentFunc else { unimplemented() }
            let checked = check(expr)
            assert(function.outputType == checked.type)
            return .return(checked)
        case .return(.none):
            guard let function = currentFunc else { unimplemented() }
            assert(function.outputType == .void)
            return jump
        }
    }

    func check(_ selection: SelectionStatement) -> SelectionStatement {
        var selection = selection
        let condition = check(selection.condition)
        assert(condition.type == .int)
        selection.condition = condition
        let previousContext = context
        selection.thenStatement = check(selection.thenStatement)
        context = previousContext
        if let elseStatement = selection.elseStatement {
            selection.elseStatement = check(elseStatement)
            context = previousContext
        }
        return selection
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
        functionDefinition.declarator
        switch functionDefinition.declarator.directDeclarator {
        case .function(.identifier(let name), let arguments):
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
        case let .minus(expr1, expr2, _):
            return .minus(check(expr1), check(expr2), .int)
        case let .plus(expr1, expr2, _):
            return .plus(check(expr1), check(expr2), .int)
        }
    }

    func check(_ expr: MultiplicativeExpression) -> MultiplicativeExpression {
        switch expr {
        case let .divide(expr1, expr2, _):
            return .divide(check(expr1), check(expr2), .int)
        case let .multiply(expr1, expr2, _):
            return .multiply(check(expr1), check(expr2), .int)
        case let .modulo(expr1, expr2, _):
            return .modulo(check(expr1), check(expr2), .int)
        }
    }
    func check(_ expr: Expression) -> Expression {
        switch expr {
        case .additive(let additiveExpr):
            return .additive(check(additiveExpr))
        case .multiplicative(let multiplicativeExpr):
            return .multiplicative(check(multiplicativeExpr))
        case .assignment(let assignment):
            return .assignment(check(assignment))
        case .unary(let unary):
            return .unary(check(unary))
        }
    }

    func check(_ assignment: AssignmentExpression) -> AssignmentExpression {
        var assignment = assignment
        switch assignment.lvalue {
        case .postfix(.primary(.identifier(let id, _))):
            let rvalue = check(assignment.rvalue)
            context[id] = rvalue.type!
            assignment.rvalue = rvalue
            return assignment
        default: unimplemented()
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
            switch postfix.type! {
            case .function(let input, let output):
                let checkedArgs = arguments.map(self.check)
                for (argument, type) in zip(checkedArgs, input)  {
                    assert(argument.type == type)
                }
                return .functionCall(postfix, checkedArgs, output)
            default: unimplemented() // TODO: Throw error
            }
        case .primary(let primary):
            return .primary(check(primary))
        }
    }

    func check(_ primary: PrimaryExpression) -> PrimaryExpression {
        switch primary {
        case .identifier(let id, _):
            return .identifier(id, context[id]!) // TODO: Throw error
        case .constant(let constant, _):
            return .constant(constant, solve(constant))
        case .string(let string, _):
            return .string(string, .array(.int))
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
