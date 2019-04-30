
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
