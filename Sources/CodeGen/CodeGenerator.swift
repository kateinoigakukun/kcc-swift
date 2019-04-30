import Parser

class X86_64Builder {
    enum Reg: String {
        case rsp
        case rbp
        case rax // for return
        case rdi // arg1
        case rsi // arg2
        case rdx // arg3
        case rcx // arg4
        case r8  // arg5
        case r9  // arg6

        static var regs: [Reg] {
            return [.rax, .rdi, .rsi, .rdx, .rcx, .r8, .r9]
        }
    }

    enum Section: String {
        case data
        case text
    }

    enum Inst: String {
        case mov
        case add
        case sub
        case mul
        case and
        case xor
        case jmp
        case push
        case pop
        case call
        case syscall
    }

    enum SystemCall: Int {
        case exit  = 1
        case write = 4
    }

    var code: String

    init() {
        self.code = ""
    }

    func raw(_ code: String) {
        self.code += code + "\n"
    }

    func section(_ section: Section) {
        self.raw("section .\(section)")
    }

    func inst(_ inst: Inst, _ dst: Any, _ src: Any) {
        self.raw("\(inst.rawValue) \(dst), \(src)")
    }

    func globalLabel(_ label: String) {
        self.raw("\(label):")
    }

    func mov(_ dst: Reg, _ src: Reg) {
        self.inst(.mov, dst, src)
    }

    func mov(_ dst: Reg, _ src: SystemCall) {
        self.inst(.mov, dst, src.rawValue)
    }

    func mov(_ dst: Reg, _ src: Int) {
        self.inst(.mov, dst, src)
    }

    func add(_ dst: Reg, _ src: Reg) {
        self.inst(.add, dst, src)
    }

    func add(_ dst: Reg, _ src: Int) {
        self.inst(.add, dst, src)
    }

    func add(_ dst: Reg, _ src: String) {
        self.inst(.add, dst, src)
    }

    func sub(_ dst: Reg, _ src: Reg) {
        self.inst(.sub, dst, src)
    }

    func sub(_ dst: Reg, _ src: Int) {
        self.inst(.sub, dst, src)
    }

    func mul(_ reg: Reg) {
        self.raw("\(Inst.mul) \(reg)")
    }

    func and(_ dst: Reg, _ src: Int) {
        self.inst(.and, dst, src)
    }

    func xor(_ dst: Reg, _ src: Reg) {
        self.inst(.xor, dst, src)
    }

    func jmp(_ label: String) {
        self.raw("\(Inst.jmp) \(label)")
    }

    func call(_ label: String) {
        self.raw("\(Inst.call) \(label)")
    }

    func push(_ reg: Reg) {
        self.raw("\(Inst.push) \(reg.rawValue)")
    }

    func pop(_ reg: Reg) {
        self.raw("\(Inst.pop) \(reg.rawValue)")
    }

    func syscall() {
        self.raw(Inst.syscall.rawValue)
    }
}

class CodeGenerator {

    let builder: X86_64Builder = .init()

    func gen(_ program: TranslationUnit) {
        builder.raw("global _main")
        builder.section(.text)
        genPrint_int()
        for decl in program.externalDecls {
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

    fileprivate func genPrint_int() {
        /*
         print_int:
         mov     r8, rdi
         mov     rax, 0x2000004
         mov     rdi, 1
         mov     [rsi], r8
         mov     rdx, 1
         syscall
         ret
        */
        builder.globalLabel("print_int")
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
