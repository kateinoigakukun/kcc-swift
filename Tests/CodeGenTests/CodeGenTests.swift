import XCTest
@testable import CodeGen
import Parser
import MirrorDiffKit

final class CodeGenTests: XCTestCase {
    func XCTAssertEqualCode(_ code: String, _ expected: String,
                            file: StaticString = #file,
                            line: UInt = #line) {
        XCTAssertEqual(
            code, expected,
            diff(
                between: code.split(separator: "\n").map(String.init),
                and: expected.split(separator: "\n").map(String.init)
            ),
            file: file, line: line
        )
    }
    func testCodeGen() throws {
        let content = """
        int main() {
            print_char(65);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let generator = CodeGenerator()
        XCTAssertEqualCode(generator.generate(unit),
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
              add rsp, 8
              ret
            _main:
              call main
              mov rax, 33554433
              mov rdi, 0
              syscall

            """
        )
    }

    func testArgument() throws {
        let content = """
        void foo(int i) {
            print_char(i);
        }
        int main() {
            foo(65);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let generator = CodeGenerator()
        XCTAssertEqualCode(generator.generate(unit),
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
            foo:
              mov rdi, rdi
              call print_char
              add rsp, 8
              ret
            main:
              mov rdi, 65
              call foo
              add rsp, 8
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
