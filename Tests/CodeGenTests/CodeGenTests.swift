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
              mov r10, rdi
              mov rax, 33554436
              mov rdi, 1
              push r10
              mov rsi, rsp
              mov rdx, 1
              syscall
              pop rbp
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
              mov r10, rdi
              mov rax, 33554436
              mov rdi, 1
              push r10
              mov rsi, rsp
              mov rdx, 1
              syscall
              pop rbp
              ret
            foo:
              mov rdi, rdi
              call print_char
              ret
            main:
              mov rdi, 65
              call foo
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
