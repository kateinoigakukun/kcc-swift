import XCTest
import Parser
@testable import Sema

final class SemaTests: XCTestCase {

    func testCheckFunctionDef() throws {
        let content = """
        int main(int arg) {
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let tc = TypeChecker()
        let context = tc.solve(unit.externalDecls.first!)
        XCTAssertEqual(context["main"], .function(input: [.int], output: .int))
    }
}
