import XCTest
@testable import Parser

final class ParserTests: XCTestCase {

    func testParseFunctionCall() throws {
        let content = "printf(1);"
        let tokens = try lex().parse(.root(content)).0
        let (result, _) = try parseUnaryExpression().parse(.root(tokens))
        switch result {
        case .postfix(let expr):
            switch expr {
            case let .functionCall(.primary(.identifier(id)),
                                arguments):
                guard case let .unary(.postfix(.primary(.constant(.integer(arg))))) = arguments[0] else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(id, "printf")
                XCTAssertEqual(arg, 1)
            default: XCTFail()
            }
        }
    }

    func testMultiDeclParse() throws {
        let content = """
        void foo() {
        }
        int main() {
            foo(1);
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 2)
    }

    func testParse() throws {
        let content = """
        int main() {
            printf("Hello, world");
        }
        """
        let tokens = try lex().parse(.root(content)).0
        XCTAssertEqual(
            tokens,
            [
                .identifier("int"), .identifier("main"),
                .leftParen,
                .rightParen, .leftBrace,
                .identifier("printf"), .leftParen,
                .string("Hello, world"),
                .rightParen, .semicolon,
                .rightBrace, .eof
            ]
        )

        let (unit, _) = try parseTranslationUnit().parse(.root(tokens))
        XCTAssertEqual(unit.externalDecls.count, 1)
        let decl = unit.externalDecls[0]
        switch decl {
        case .functionDefinition(let function):
            XCTAssertEqual(function.declarationSpecifier, [.typeSpecifier(.int)])
            XCTAssertEqual(function.declarator.directDeclarator, .declaratorWithIdentifiers(.identifier("main"), []))
            XCTAssertEqual(function.compoundStatement.statement.count, 1)
        default: XCTFail()
        }
    }
}
