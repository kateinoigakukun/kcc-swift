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
        case .functionDefinition(let def):
            XCTAssertEqual(def.inputType, [.int])
            XCTAssertEqual(def.outputType, .int)
        default: XCTFail()
        }
        guard case .functionDefinition(let def) = checked.externalDecls[1] else {
            XCTFail()
            return
        }
        let stmt = def.compoundStatement.statement[0]
        guard case .expression(let expr) = stmt else {
            XCTFail()
            return
        }
        guard case .some(
            .unary(.postfix(.functionCall(
                let name, let args, let type)))) = expr.expression else {
                    XCTFail()
                    return
        }
        XCTAssertEqual(name.type, .function(input: [.int], output: .int))
        XCTAssertEqual(args.map { $0.type }, [.int])
        XCTAssertEqual(type, .int)
    }

    func testCheckArguments() throws {
        let content = """
        void rec(int count) {
            print_char(count);
            if(count-100) {
            } else {
                return;
            }
            rec(count+1);
            return;
        }
        void main() {
            rec(97);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let tc = TypeChecker(unit: unit)
        _ = tc.check()
    }
}
