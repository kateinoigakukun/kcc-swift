protocol Register {
    var rawValue: String { get }
}
enum Reg: String, Register {
    case rax
    case rbp
    case rsp

    @available(*, deprecated)
    case rdi, rdx, r8
}
enum ArgReg: String, Register, CaseIterable {
    case rdi, rsi, rdx, rcx, r8, r9
}

enum Section: String {
    case data
    case text
}

enum SystemCall: Int {
    case exit  = 0x2000001
    case write = 0x2000004
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

    func section(_ section: Section) {
        self.raw("section .\(section)")
    }

    func inst(_ inst: String, _ dst: String, _ src: String) {
        self.raw("  \(inst) \(dst), \(src)")
    }

    func globalLabel(_ label: String) {
        self.raw("\(label):")
    }

    func mov(_ dst: ArgReg, _ src: CodeGenerator.Reference) {
        switch src {
        case .register(let srcReg):
            self.inst("mov", dst.rawValue, srcReg.rawValue)
        case .primitive(let integer):
            self.inst("mov", dst.rawValue, integer.description)
        default: unimplemented()
        }
    }
    func mov(_ dst: Reg, _ src: Reg) {
        self.inst("mov", dst.rawValue, src.rawValue)
    }

    func mov(_ dst: Reg, _ src: SystemCall) {
        self.inst("mov", dst.rawValue, src.rawValue.description)
    }

    func mov(_ dst: Reg, _ src: Int) {
        self.inst("mov", dst.rawValue, src.description)
    }
    func mov(_ dst: Reg, _ src: String) {
        self.inst("mov", dst.rawValue, src)
    }

    func call(_ label: String) {
        self.raw("  call \(label)")
    }

    func syscall() {
        self.raw("  syscall")
    }

    func push(_ value: Int) {
        stack.depth += 8
        self.raw("  push \(value)")
    }

    func push(_ reg: Reg) {
        stack.depth += 8
        self.raw("  push \(reg.rawValue)")
    }

    func pop(_ reg: Reg) {
        stack.depth -= 8
        self.raw("  pop \(reg.rawValue)")
    }

    func add(_ reg: Reg, _ value: Int) {
        self.inst("add", reg.rawValue, value.description)
    }

    func ret() {
        self.raw("  ret")
    }
}
