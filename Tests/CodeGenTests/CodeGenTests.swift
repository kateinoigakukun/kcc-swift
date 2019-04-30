import XCTest
@testable import CodeGen
import Parser

final class CodeGenTests: XCTestCase {
    func testCodeGen() throws {
        let content = """
        int main() {
            print_char(65);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let generator = CodeGenerator()
        XCTAssertEqual(
            generator.generate(unit),
            """
            global _main
            section .text
            print_char:
            mov r8, rdi
            mov rax, 33554436
            mov rdi, 1
            mov [rsi], r8
            mov rdx, 1
            syscall
            ret
            main:
            mov rdi, 65
            call print_char
            ret
            _main:
            call main
            mov rax, 33554433
            mov rdi, 0
            syscall

            """
        )
    }
}
