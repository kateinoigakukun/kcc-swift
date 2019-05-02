import Parser

public class CodeGenerator {
    enum Reference {
        case register(Operandable)
        case stack(depth: Int)
        case primitive(Int)
    }
    struct Binding {
        let type: TypeSpecifier
        let ref: Reference
    }
    enum Context {
        case `func`(FunctionDefinition, returnLabel: String)
    }
    class Scope {
        private var table: [String: Binding] = [:]
        private weak var parent: Scope?
        let context: Context
        init(context: Context) { self.context = context }
        private init(context: Context, parent: Scope) {
            self.context = context
            self.parent = parent
        }
        subscript(_ identifier: String) -> Binding? {
            get {
                return table[identifier] ?? parent?[identifier]
            }
            set {
                table[identifier] = newValue
            }
        }

        func makeChild(_ context: Context) -> Scope {
            return Scope(context: context, parent: self)
        }
    }
    let builder: BuilderOverloads = X86_64Builder.init()

    public init() {}
    public func generate(_ unit: TranslationUnit) -> String {
        gen(unit)
        return builder.code
    }
    fileprivate func gen(_ unit: TranslationUnit) {
        builder.global("_main")
        builder.section(.text)
        genPrint_char()
        for decl in unit.externalDecls {
            gen(decl)
        }
        genEntry()
    }

    fileprivate func gen(_ decl: ExternalDeclaration) {
        switch decl {
        case .functionDefinition(let funcDefinition):
            gen(funcDefinition)
        default:
            unimplemented()
        }
    }

    fileprivate func gen(_ funcDefinition: FunctionDefinition) {
        switch funcDefinition.declarator.directDeclarator {
        case .declaratorWithIdentifiers(.identifier(let name), let arguments):
            builder.label(name)
             // TODO: Make scope from global scope
            let returnLabel = builder.newLabel()
            var scope = Scope(
                context: .func(funcDefinition, returnLabel: returnLabel)
            )
            var stackDepth: Int = 0
            builder.push(.rbp)
            builder.mov(.rbp, .rsp)
            for (index, argument) in arguments.enumerated() {
                guard case let .identifier(id) = argument.declarator.directDeclarator else {
                    unimplemented()
                }
                // TODO: support type check
                let register = ArgReg.allCases[index]
                stackDepth += 8
                let reference = Reference.stack(depth: stackDepth)
                builder.push(register)
                scope[id] = Binding(type: .int, ref: reference)
            }
            for statement in funcDefinition.compoundStatement.statement {
                scope = gen(statement, scope: scope)
            }
            builder.label(returnLabel)
            builder.mov(.rsp, .rbp)
            builder.pop(.rbp)
            builder.ret()
        default: unimplemented()
        }
    }

    fileprivate func gen(_ statement: Statement, scope: Scope) -> Scope {
        switch statement {
        case .expression(let exprStatement):
            guard let expr = exprStatement.expression else { unimplemented() }
            return gen(expr, scope: scope).1
        case .jump(let jumpStatement):
            return gen(jumpStatement, scope: scope)
        case .compound(let compoundStatement):
            var scope = scope
            for statement in compoundStatement.statement {
                scope = gen(statement, scope: scope)
            }
            return scope
        case .selection(let selectionStatement):
            return gen(selectionStatement, scope: scope)
        }
    }

    fileprivate func gen(_ selection: SelectionStatement, scope: Scope) -> Scope {
        switch selection {
        case .if(let expr, let stmt, let elseStmt):
            var (ref, scope) = gen(expr, scope: scope)
            let elseLabel = builder.newLabel()
            let endLabel = builder.newLabel()
            switch ref {
            case .primitive(let value):
                // Compile time computing optimization
                if value != 0 {
                    scope = gen(stmt, scope: scope)
                } else if let elseStmt = elseStmt {
                    scope = gen(elseStmt, scope: scope)
                }
                return scope
            case .stack:
                // Avoid to compare stack value directly
                builder.mov(.r10, ref)
                ref = .register(Reg.r10)
            default: break
            }
            builder.cmp(ref, 0)
            builder.je(elseLabel)

            scope = gen(stmt, scope: scope)
            builder.jmp(endLabel)

            builder.label(elseLabel)
            if let elseStmt = elseStmt {
                scope = gen(elseStmt, scope: scope)
            }
            builder.label(endLabel)
            return scope
        }
    }


    fileprivate func gen(_ jumpStatement: JumpStatement, scope: Scope) -> Scope {
        switch jumpStatement {
        case .return(let optionalExpr):
            var scope = scope
            guard case let .func(_, returnLabel) = scope.context else {
                unimplemented()
            }
            if let expr = optionalExpr {
                let (ref, _scope) = gen(expr, scope: scope)
                builder.mov(.rax, ref)
                scope = _scope
            }
            builder.jmp(returnLabel)
            return scope
        }
    }

    fileprivate func gen(_ expr: Expression, scope: Scope) -> (Reference, Scope) {
        switch expr {
        case .assignment(let assignment):
            return gen(assignment, scope: scope)
        case .additive(_):
            unimplemented()
        case .unary(let unary):
            return gen(unary, scope: scope)
        }
    }
    fileprivate func gen(
        _ assignment: AssignmentExpression, scope: Scope
        ) -> (Reference, Scope) {
        unimplemented()
    }

    fileprivate func gen(_ unary: UnaryExpression, scope: Scope) -> (Reference, Scope) {
        switch unary {
        case .postfix(let postfix):
            return gen(postfix, scope: scope)
        }
    }

    fileprivate func gen(_ postfix: PostfixExpression, scope: Scope) -> (Reference, Scope) {
        switch postfix {
        case .functionCall(let postfix, let arguments):
            return genFunctionCall(postfix, arguments, scope: scope)
        case .primary(.identifier(let identifier)):
            return (scope[identifier]!.ref, scope)
        case .primary(.constant(.integer(let integer))):
            return (.primitive(integer), scope)
        default: unimplemented()
        }
    }

    fileprivate func genFunctionCall(
        _ postfix: PostfixExpression,
        _ arguments: [Expression], scope: Scope) -> (Reference, Scope) {
        switch postfix {
        case .primary(.identifier(let identifier)):
            let arguments = arguments.map { self.gen($0, scope: scope) }
            for (index, (reference, _)) in arguments.enumerated() {
                let dist = ArgReg.allCases[index]
                builder.mov(dist, reference)
            }
            builder.call(identifier)
//            Comment out until supporting multiple arguments than 6
//            builder.add(.rsp, arguments.count * 8)
            return (.register(Reg.rax), scope)
        default: unimplemented()
        }
    }

    fileprivate func genEntry() {
        /*
         _main:
         call main
         mov     rax, 0x2000001
         mov     rdi, 0
         syscall

        */
        builder.label("_main")
        builder.call("main")
        builder.mov(.rax, .exit)
        builder.mov(.rdi, 0)
        builder.syscall()
    }

    fileprivate func genPrint_char() {
        /*
         print_char:
         mov     r8, rdi
         mov     rax, 0x2000004
         mov     rdi, 1
         mov     [rsi], r8
         mov     rdx, 1
         syscall
         ret
        */
        builder.label("print_char")
        builder.push(.rbp)
        builder.mov(.r10, .rdi)
        builder.mov(.rax, .write)
        builder.mov(.rdi, 1)
        builder.push(.r10)
        builder.mov(.rsi, .rsp)
        builder.mov(.rdx, 1)
        builder.syscall()
        builder.pop(.rbp)
        builder.pop(.rbp)
        builder.ret()
    }
}

func unimplemented() -> Never {
    fatalError("unimplemented")
}
