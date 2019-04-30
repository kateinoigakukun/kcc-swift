import Parser

public class CodeGenerator {

    let builder: X86_64Builder = .init()
    public init() {}
    public func generate(_ unit: TranslationUnit) -> String {
        gen(unit)
        return builder.code
    }
    func gen(_ unit: TranslationUnit) {
        builder.raw("global _main")
        builder.section(.text)
        genPrint_char()
        for decl in unit.externalDecls {
            gen(decl)
        }
        gen_main()
    }
    fileprivate func gen(_ decl: ExternalDeclaration) {
        switch decl {
        case .functionDefinition(let funcDefinition):
            switch funcDefinition.declarator.directDeclarator {
            case .declaratorWithIdentifiers(.identifier(let name), _):
                builder.globalLabel(name)
                for statement in funcDefinition.compoundStatement.statement {
                    gen(statement)
                }
                builder.raw("ret")
            default: notImplemented()
            }
        default:
            notImplemented()
        }
    }

    fileprivate func gen(_ statement: Statement) {
        switch statement {
        case .expression(let exprStatement):
            guard let expr = exprStatement.expression else { notImplemented() }
            gen(expr)
        }
    }

    fileprivate func gen(_ expr: Expression) {
        if let (funcName, argument) = expr.functionCall {
            builder.mov(.rdi, argument)
            builder.call(funcName)
        }
    }

    fileprivate func gen_main() {
        /*
         _main:
         call main
         mov     rax, 0x2000001
         mov     rdi, 0
         syscall

        */
        builder.globalLabel("_main")
        builder.call("main")
        builder.mov(.rax, 0x2000001)
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
        builder.globalLabel("print_char")
        builder.mov(.r8, .rdi)
        builder.mov(.rax, 0x2000004)
        builder.mov(.rdi, 1)
        builder.raw("mov [rsi], r8")
        builder.mov(.rdx, 1)
        builder.syscall()
        builder.raw("ret")
    }
}

func notImplemented() -> Never {
    fatalError("Not implemented")
}
