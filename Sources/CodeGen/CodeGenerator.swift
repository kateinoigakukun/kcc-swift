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
        case global
    }
    class Scope {
        private var table: [String: Binding] = [:]
        private weak var parent: Scope?
        let context: Context
        static func global() -> Scope { return Scope(context: .global) }
        private init(context: Context) { self.context = context }
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
    let global = Scope.global()

    public init() {}
    public func generate(_ unit: TranslationUnit) -> String {
        gen(unit)
        return builder.code
    }
    fileprivate func gen(_ unit: TranslationUnit) {
        builder.global("_main")
        builder.section(.text)
        genPrint_char()
        genAdd()
        genSub()
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
        case .function(.identifier(let name), let arguments):
            builder.label(name)
             // TODO: Make scope from global scope
            let returnLabel = builder.newLabel()
            var scope = global.makeChild(
                .func(funcDefinition, returnLabel: returnLabel)
            )
            var stackDepth: Int = 0
            builder.push(.rbp)
            builder.mov(.rbp, .rsp)
            for (index, argument) in arguments.enumerated() {
                guard case let .identifier(id) = argument.declarator.directDeclarator else {
                    unimplemented()
                }
                let register = ArgReg.allCases[index]
                stackDepth += 8
                let reference = Reference.stack(depth: stackDepth)
                builder.push(register)
                scope[id] = Binding(type: .int, ref: reference)
            }
            for decl in funcDefinition.compoundStatement.declaration {
                let (newScope, newStackDepth) = gen(
                    decl, scope: scope, stackDepth: stackDepth
                )
                scope = newScope
                stackDepth = newStackDepth
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

    fileprivate func gen(_ decl: Declaration, scope: Scope, stackDepth: Int) -> (scope: Scope, stackDepth: Int) {
        var stackDepth = stackDepth
        for initDeclarator in decl.initDeclarator {
            switch initDeclarator.declarator.directDeclarator {
            case .identifier(let name):
                // TODO: Use declarationSpecifier
                stackDepth += 8
                let reference = Reference.stack(depth: stackDepth)
                scope[name] = Binding(type: .int, ref: reference)
                guard let initializer = initDeclarator.initializer else {
                    builder.push(0) // Zero initialize
                    continue
                }
                switch initializer {
                case .expression(let expr):
                    let value = gen(expr, scope: scope)
                    builder.push(value)
                default: unimplemented()
                }
            default: unimplemented()
            }
        }
        return (scope, stackDepth)
    }

    fileprivate func gen(_ statement: Statement, scope: Scope) -> Scope {
        switch statement {
        case .expression(let exprStatement):
            guard let expr = exprStatement.expression else { unimplemented() }
            _ = gen(expr, scope: scope)
            return scope
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
        let ref = gen(selection.condition, scope: scope)
        let elseLabel = builder.newLabel()
        let endLabel = builder.newLabel()
        builder.mov(.r10, ref)
        builder.cmp(.r10, 0)
        builder.je(elseLabel)

        _ = gen(selection.thenStatement, scope: scope)
        builder.jmp(endLabel)

        builder.label(elseLabel)
        if let elseStatement = selection.elseStatement {
            _ = gen(elseStatement, scope: scope)
        }
        builder.label(endLabel)
        return scope
    }


    fileprivate func gen(_ jumpStatement: JumpStatement, scope: Scope) -> Scope {
        switch jumpStatement {
        case .return(let optionalExpr):
            guard case let .func(_, returnLabel) = scope.context else {
                unimplemented()
            }
            if let expr = optionalExpr {
                let ref = gen(expr, scope: scope)
                builder.mov(.rax, ref)
            }
            builder.jmp(returnLabel)
            return scope
        }
    }

    fileprivate func gen(_ expr: Expression, scope: Scope) -> Reference {
        switch expr {
        case .assignment(let assignment):
            return gen(assignment, scope: scope)
        case .additive(let additive):
            return gen(additive, scope: scope)
        case .unary(let unary):
            return gen(unary, scope: scope)
        case .functionCall(let functionCall):
            return gen(functionCall, scope: scope)
        case .primary(.identifier(let identifier, _)):
            return scope[identifier]!.ref
        case .primary(.constant(.integer(let integer), _)):
            return .primitive(integer)
        case .primary(.string(_, _)):
            unimplemented()
        case .multiplicative:
            unimplemented()
        }
    }

    fileprivate func gen(
        _ assignment: AssignmentExpression, scope: Scope
        ) -> Reference {
        switch assignment.operator {
        case .equal:
            let lValue = gen(assignment.lvalue, scope: scope)
            let rValue = gen(assignment.rvalue, scope: scope)
            // TODO: Size is fixed as Int. Change size by variable type later
            builder.mov(lValue, "dword \(rValue.asOperand())")
            return rValue
        }
    }

    fileprivate func gen(_ additive: AdditiveExpression, scope: Scope) -> Reference {
        switch additive {
        case let .plus(expr1, expr2, _):
            let call = FunctionCallExpression(
                name: .primary(.identifier("_add", nil)),
                argumentList: [expr1, expr2],
                type: nil
            )
            return gen(call, scope: scope)
        case let .minus(expr1, expr2, _):
            let call = FunctionCallExpression(
                name: .primary(.identifier("_sub", nil)),
                argumentList: [expr1, expr2],
                type: nil
            )
            return gen(call, scope: scope)
        }
    }
    fileprivate func gen(_ unary: UnaryExpression, scope: Scope) -> Reference {
        switch unary.operator {
        case .and:
            let ref = gen(unary.expression, scope: scope)
            let pointer: Reference
            switch ref {
            case .stack(let depth):
                builder.mov(.r10, .rbp)
                builder.sub(.r10, depth)
                pointer = .register(Reg.r10)
            default: unimplemented()
            }
            return pointer
        case .star:
            let ref = gen(unary.expression, scope: scope)
            builder.mov(.r11, ref.asOperand())
            builder.mov(.r10, "[r11]")
            return .register(Reg.r10)
        }
    }

    fileprivate func gen(_ functionCall: FunctionCallExpression, scope: Scope) -> Reference {
        switch functionCall.name {
        case .primary(.identifier(let identifier, _)):
            let arguments = functionCall.argumentList.map { self.gen($0, scope: scope) }
            for (index, reference) in arguments.enumerated() {
                let dist = ArgReg.allCases[index]
                builder.mov(dist, reference)
            }
            builder.call(identifier)
//            Comment out until supporting multiple arguments than 6
//            builder.add(.rsp, arguments.count * 8)
            return .register(Reg.rax)
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

    fileprivate func genAdd() {
        builder.label("_add")
        builder.push(.rbp)
        builder.mov(.rbp, .rsp)
        let arguments = ArgReg.allCases[0...1]
        builder.mov(.rax, arguments[0])
        builder.add(.rax, arguments[1])
        builder.mov(.rsp, .rbp)
        builder.pop(.rbp)
        builder.ret()
    }

    fileprivate func genSub() {
        builder.label("_sub")
        builder.push(.rbp)
        builder.mov(.rbp, .rsp)
        let arguments = ArgReg.allCases[0...1]
        builder.mov(.rax, arguments[0])
        builder.sub(.rax, arguments[1])
        builder.mov(.rsp, .rbp)
        builder.pop(.rbp)
        builder.ret()
    }
}

func unimplemented(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("unimplemented", file: file, line: line)
}
