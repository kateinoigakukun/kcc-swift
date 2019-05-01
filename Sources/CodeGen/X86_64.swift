protocol Operandable {
    func asOperand() -> String
}
extension Operandable where Self: RawRepresentable, Self.RawValue == String {
    func asOperand() -> String { return rawValue }
}
extension Operandable where Self: RawRepresentable, Self.RawValue == Int {
    func asOperand() -> String { return rawValue.description }
}

extension Int: Operandable {
    func asOperand() -> String { return description }
}

extension String: Operandable {
    func asOperand() -> String { return self }
}

enum Reg: String, Operandable {
    case rax, rbp,
    rsp, r10,
    r11, rbx,
    r12, r13,
    r14, r15
}

enum ArgReg: String, Operandable, CaseIterable {
    case rdi, rsi, rdx, rcx, r8, r9
}

enum Section: String {
    case data
    case text
}


enum SystemCall: Int, Operandable {
    case exit  = 0x2000001
    case write = 0x2000004
}
