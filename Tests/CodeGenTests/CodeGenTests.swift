import XCTest
@testable import CodeGen
import Parser
import MirrorDiffKit

final class CodeGenTests: XCTestCase {
    func testCodeGen() throws {
        let content = """
        int main() {
            print_char(72);
            print_char(101);
            print_char(108);
            print_char(108);
            print_char(111);
            print_char(44);
            print_char(32);
            print_char(119);
            print_char(111);
            print_char(114);
            print_char(108);
            print_char(100);
            print_char(33);
        }
        """
        try XCTAssertEqual(executeSource(content), "Hello, world!")
    }

    func testReturn() throws {
        let content = """
        int foo() {
            return 65;
        }
        int main() {
            print_char(foo());
        }
        """
        try XCTAssertEqual(executeSource(content), "A")
    }

    func testIfPrimitive() throws {
        let content = """
        int main() {
            if (1) {
                print_char(65);
            }
        }
        """
        try XCTAssertEqual(executeSource(content), "A")
    }

    func testIfElsePrimitive() throws {
        let content = """
        int main() {
            if (0) {
                print_char(65);
            } else {
                print_char(66);
            }
        }
        """
        try XCTAssertEqual(executeSource(content), "B")
    }

    func testIf() throws {
        let content = """
        int foo() {
            return 1;
        }
        int main() {
            if (foo()) {
                print_char(65);
            }
        }
        """
        try XCTAssertEqual(executeSource(content), "A")
    }

    func testIfElse() throws {
        let content = """
        int foo() {
            return 0;
        }
        int main() {
            if (foo()) {
                print_char(65);
            } else {
                print_char(66);
            }
        }
        """
        try XCTAssertEqual(executeSource(content), "B")
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
        try XCTAssertEqual(executeSource(content), "A")
    }
}


// MARK: - Helper
extension CodeGenTests {

    func executeSource(_ source: String) throws -> String {
        let tokens = try lex(source)
        let unit = try parse(tokens)
        let generator = CodeGenerator()
        let code = generator.generate(unit)
        return try executeCode(code)
    }

    func executeCode(_ code: String) throws -> String {
        let tmpExec = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString).path
        try compile(code, output: tmpExec)
        let ps = Process()
        ps.launchPath = tmpExec
        let outputPipe = Pipe()
        var outputData = Data()
        let outputSource = DispatchSource.makeReadSource(
            fileDescriptor: outputPipe.fileHandleForReading.fileDescriptor)
        outputSource.setEventHandler {
            outputData.append(outputPipe.fileHandleForReading.availableData)
        }
        outputSource.resume()
        ps.standardOutput = outputPipe
        ps.launch()
        ps.waitUntilExit()
        return String(data: outputData, encoding: .utf8)!
    }
    func compile(_ code: String, output: String) throws {
        let tmpFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("asm").path
        try code.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        nasm(tmpFile)
        let objectFilePath = tmpFile
            .split(separator: ".").dropLast()
            .joined(separator: ".") + ".o"
        ld(objectFile: objectFilePath, output: output)
    }

    func nasm(_ file: String) {
        let ps = Process()
        ps.launchPath = "/usr/local/bin/nasm"
        ps.arguments = ["-f", "macho64", file]
        ps.launch()
        ps.waitUntilExit()
    }

    func ld(objectFile: String, output: String) {
        let ps = Process()
        ps.launchPath = "/usr/bin/ld"
        ps.arguments = ["-macosx_version_min", "10.14", "-lSystem", "-o", output, objectFile]
        ps.launch()
        ps.waitUntilExit()
    }

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
}
