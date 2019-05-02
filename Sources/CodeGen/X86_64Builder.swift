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
    func mov(_ dst: Reg, _ src: CodeGenerator.Reference)
    func mov(_ dst: ArgReg, _ src: CodeGenerator.Reference)

    func pop(_ reg: Reg)
    func push(_ reg: Reg)
    func push(_ reg: Operandable)

    func jmp(_ label: String)
    func je(_ label: String)

    func cmp(_ value1: Int, _ value2: Int)
    func cmp(_ value1: CodeGenerator.Reference, _ value2: Int)

    func newLabel() -> String
}

class X86_64Builder {
    var code: String
    var labelNumber: Int

    init() {
        self.code = ""
        self.labelNumber = 0
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
        push(reg as Operandable)
    }
    func push(_ reg: Operandable) {
        self.inst("push", reg)
    }

    func pop(_ reg: Reg) {
        self.inst("pop", reg)
    }

    func add(_ reg: Reg, _ value: Int) {
        self.inst("add", reg, value)
    }

    func jmp(_ label: String) {
        self.inst("jmp", label)
    }

    func je(_ label: String) {
        self.inst("je", label)
    }

    func cmp<V1: Operandable, V2: Operandable>(_ value1: V1, _ value2: V2) {
        self.inst("cmp", value1, value2)
    }

    func newLabel() -> String {
        defer { labelNumber += 1 }
        return ".L\(labelNumber)"
    }
}

extension X86_64Builder: BuilderOverloads {}

extension CodeGenerator.Reference: Operandable {
    func asOperand() -> String {
        switch self {
        case .register(let srcReg): return srcReg.asOperand()
        case .primitive(let integer):
            return integer.description
        case .stack(let depth):
            return "[rbp - \(depth)]"
        }
    }
}
