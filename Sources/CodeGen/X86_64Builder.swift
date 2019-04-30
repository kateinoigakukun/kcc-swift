enum Reg: String {
    case rax
    case rdi
    case rdx
    case r8
}

enum Section: String {
    case data
    case text
}

enum Inst: String {
    case mov
    case call
    case syscall
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

    func call(_ label: String) {
        self.raw("\(Inst.call) \(label)")
    }

    func syscall() {
        self.raw(Inst.syscall.rawValue)
    }
}
