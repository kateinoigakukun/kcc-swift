// For making overloads easily
protocol BuilderOverloads {
    var code: String { get }

    func section(_ section: Section)

    func global(_ name: String)
    func label(_ label: String)

    func call(_ label: String)

    func syscall()

    func ret()

    func mov(_ dst: Reg, _ src: Reg)
    func mov(_ dst: Reg, _ src: ArgReg)
    func mov(_ dst: ArgReg, _ src: Reg)
    func mov(_ dst: Reg, _ src: SystemCall)
    func mov(_ dst: ArgReg, _ src: Int)
    func mov(_ dst: Reg, _ src: Int)
    func mov(_ dst: ArgReg, _ src: CodeGenerator.Reference)

    func pop(_ reg: Reg)
    func push(_ reg: Reg)
}

class X86_64Builder {
    var code: String
    let stack: Stack
    class Stack {
        fileprivate(set) var depth: Int = 0
    }

    init() {
        self.code = ""
        self.stack = .init()
    }

    func raw(_ code: String) {
        self.code += code + "\n"
    }

    func inst(_ inst: String) {
        self.raw("  \(inst)")
    }

    func inst(_ inst: String, _ target: Operandable) {
        self.raw("  \(inst) \(target.asOperand())")
    }

    func inst(_ inst: String, _ dst: Operandable, _ src: Operandable) {
        self.raw("  \(inst) \(dst.asOperand()), \(src.asOperand())")
    }

    func section(_ section: Section) { self.raw("section .\(section)") }
    func global(_ name: String) { self.raw("global \(name)") }
    func label(_ label: String) { self.raw("\(label):") }
    func call(_ label: String) { self.inst("call", label) }
    func syscall() { self.inst("syscall") }
    func ret() { self.inst("ret") }

    func mov<D: Operandable, S: Operandable>(_ dst: D, _ src: S) {
        self.inst("mov", dst, src)
    }

    func push(_ reg: Reg) {
        stack.depth += 8
        self.inst("push", reg)
    }

    func pop(_ reg: Reg) {
        stack.depth -= 8
        self.inst("pop", reg)
    }

    func add(_ reg: Reg, _ value: Int) {
        self.inst("add", reg, value)
    }
}

extension X86_64Builder: BuilderOverloads {}

extension CodeGenerator.Reference: Operandable {
    func asOperand() -> String {
        switch self {
        case .register(let srcReg): return srcReg.asOperand()
        case .primitive(let integer):
            return integer.description
        default: unimplemented()
        }
    }
}
