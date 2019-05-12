import XCTest
@testable import Parser
@testable import Sema

final class SemaTests: XCTestCase {

    func testCheckFunctionDef() throws {
        let content = """
        int foo(int bar) {}
        int main(int arg) {
            foo(arg);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let tc = TypeChecker(unit: unit)
        XCTAssertEqual(tc.context["main"], .function(input: [.int], output: .int))
        let checked = tc.check()
        switch checked.externalDecls[0] {
        case .functionDefinition(let def): break
        default: XCTFail()
        }
        dump(checked)
    }
}
