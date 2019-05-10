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
        let tc = TypeChecker(unit: unit)
        let context = tc.makeContext(unit.externalDecls.first!)
        XCTAssertEqual(context["main"], .function(input: [.int], output: .int))
    }
}
