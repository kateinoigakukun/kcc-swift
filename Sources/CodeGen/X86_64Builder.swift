enum Reg: String {
    case rax
    case rdi
    case rdx
    case r8
    case rbp
    case rsp
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

    init() {
        self.code = ""
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
        self.raw("  push \(value)")
    }

    func push(_ reg: Reg) {
        self.raw("  push \(reg.rawValue)")
    }

    func pop(_ reg: Reg) {
        self.raw("  pop \(reg.rawValue)")
    }

    func add(_ reg: Reg, _ value: Int) {
        self.inst("add", reg.rawValue, value.description)
    }
}
