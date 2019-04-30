import XCTest
@testable import CodeGen
import Parser

final class CodeGenTests: XCTestCase {
    func testCodeGen() throws {
        let content = """
        int main() {
            print_int(65);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let generator = CodeGenerator()
        generator.gen(unit)
        XCTAssertEqual(
            generator.builder.code,
            """
            global _main
            section .text
            print_int:
            mov r8, rdi
            mov rax, 33554436
            mov rdi, 1
            mov [rsi], r8
            mov rdx, 1
            syscall
            ret
            main:
            mov rdi, 65
            call print_int
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
