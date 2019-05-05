import Parser

public class TypeChecker {

    func solve(_ expr: Expression, context: DeclContext) -> Type {
        switch expr {
        case .additive, .multiplicative:
            return .int
        case .assignment(let assignment):
            return solve(assignment.rvalue, context: context)
        case .unary(let unary):
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
