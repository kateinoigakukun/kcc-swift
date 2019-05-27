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
        let checked = try tc.check()
        guard case .functionDefinition(let foo) = checked.externalDecls[0] else {
            XCTFail(); return
        }
        XCTAssertEqual(foo.inputType, [.int])
        XCTAssertEqual(foo.outputType, .int)
        guard
            case .functionDefinition(let main) = checked.externalDecls[1],
            case .expression(let expr) = main.compoundStatement.statement[0],
            case .functionCall(let call)? = expr.expression else {
                XCTFail(); return
        }
        XCTAssertEqual(call.name.type, .function(input: [.int], output: .int))
        XCTAssertEqual(call.argumentList.map { $0.type }, [.int])
        XCTAssertEqual(call.type, .int)
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
        int main() {
            rec(97);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let tc = TypeChecker(unit: unit)
        _ = try tc.check()
    }

    func testCheckPointer() throws {
        let content = """
        int main() {
            int value = 0;
            int *ref = &value;
            return 0;
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        let tc = TypeChecker(unit: unit)
        let checked = try tc.check()
        let main = checked.externalDecls.first!.functionDefinition!
        let ref = main.compoundStatement.declaration[1]
        guard case .expression(let expr)? = ref.initDeclarator[0].initializer else {
            XCTFail(); return
        }
        XCTAssertEqual(expr.type, Type.pointer(.int))
    }
}
