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
    class Scope {
        private var table: [String: Binding] = [:]
        private weak var parent: Scope?
        init() {}
        private init(parent: Scope) {
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

        func makeChild() -> Scope {
            return Scope(parent: self)
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
            var scope = Scope()
            for (index, argument) in arguments.enumerated() {
                guard case let .identifier(id) = argument.declarator.directDeclarator else {
                    unimplemented()
                }
                // TODO: support type check
                let register = ArgReg.allCases[index]
                scope[id] = Binding(type: .int, ref: .register(register))
            }
            for statement in funcDefinition.compoundStatement.statement {
                scope = gen(statement, scope: scope)

            }
            builder.ret()
        default: unimplemented()
        }
    }

    fileprivate func gen(_ statement: Statement, scope: Scope) -> Scope {
        switch statement {
        case .expression(let exprStatement):
            guard let expr = exprStatement.expression else { unimplemented() }
            return gen(expr, scope: scope)
        }
    }

    fileprivate func gen(_ expr: Expression, scope: Scope) -> Scope {
        switch expr {
        case .assignment(let assignment):
            return gen(assignment, scope: scope).1
        }
    }
    fileprivate func gen(
        _ assignment: AssignmentExpression, scope: Scope
        ) -> (Reference, Scope) {
        switch assignment {
        case .unary(let unary):
            return gen(unary, scope: scope)
        default: unimplemented()
        }
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
        _ arguments: [AssignmentExpression], scope: Scope) -> (Reference, Scope) {
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
        builder.mov(.r10, .rdi)
        builder.mov(.rax, .write)
        builder.mov(.rdi, 1)
        builder.push(.r10)
        builder.mov(.rsi, .rsp)
        builder.mov(.rdx, 1)
        builder.syscall()
        builder.pop(.rbp)
        builder.ret()
    }
}

func unimplemented() -> Never {
    fatalError("unimplemented")
}
