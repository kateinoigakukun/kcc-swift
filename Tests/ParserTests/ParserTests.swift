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
                guard case let .unary(.postfix(.primary(.constant(.integer(arg)))), nil) = arguments[0] else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(id, "printf")
                XCTAssertEqual(arg, 1)
            default: XCTFail()
            }
        }
    }

    func testParseReturnStatement() throws {
        let content = "return 1;"
        let tokens = try lex(content)
        let (statement, _) = try parseJumpStatement().parse(.root(tokens))
        switch statement {
        case .return(let expr):
            XCTAssertNotNil(expr)
        }
    }

    func testParseReturnFunc() throws {
        let content = """
        int foo() {
            return 1;
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
    }

    func testParseMultiPlus() throws {
        let content = "1 + 2 + 3"
        let tokens = try lex(content)
        let (expr, tail) = try parseExpression().parse(.root(tokens))
        let integer = {
            Expression.unary(
                .postfix(
                    .primary(
                        .constant(Constant.integer($0))
                    )
                ),
                nil
            )
        }
        XCTAssertEqual(
            expr,
            .additive(
                .plus(.
                    additive(
                        .plus(integer(1), integer(2)),
                        nil
                    ),
                    integer(3)
                ),
                nil
            )
        )
        XCTAssertEqual(tail.collection[tail.startIndex], .eof)
    }

    func testParseMultiPlusMinus() throws {
        let content = "1 - 2 + 3 - 4"
        let tokens = try lex(content)
        let (expr, tail) = try parseExpression().parse(.root(tokens))
        let integer = {
            Expression.unary(
                .postfix(
                    .primary(
                        .constant(.integer($0))
                    )
                ),
                nil
            )
        }
        XCTAssertEqual(
            expr,
            .additive(
                .minus(
                    .additive(
                        .plus(
                            .additive(
                                .minus(integer(1), integer(2)),
                                nil
                            ),
                            integer(3)
                        ),
                        nil
                    ),
                    integer(4)
                ),
                nil
            )
        )
        dump(expr)
        XCTAssertEqual(tail.collection[tail.startIndex], .eof)
    }

    func testParseAddExpr() throws {
        let content = """
        int foo() {
            return 1 + 1 + 1;
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
    }

    func testParseIfStatement() throws {
        let content = "if (1) 1;"
        let tokens = try lex(content)
        let (statement, _) = try parseSelectionStatement().parse(.root(tokens))
        guard case let .unary(
            .postfix(.primary(
                .constant(.integer(value)))), _) = statement.condition else {
                    XCTFail()
                    return
        }
        XCTAssertEqual(value, 1)
    }

    func testParseIf() throws {
        let content = """
        int foo() {
            if(1) {
                return 1;
            }
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
    }

    func testParseIfElse() throws {
        let content = """
        int foo() {
            if(1) {
                return 1;
            } else {
                return 2;
            }
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
    }

    func testVarParse() throws {
        let content = """
        int main() {
            int value = 1;
            value = 65;
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
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

    func testArgumentParse() throws {
        let content = """
        int main(int args) {
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
    }

    func testParseDecl() throws {
        let content = """
        void main() {
            int value = 0;
        }
        """
        let tokens = try lex(content)
        let unit = try parse(tokens)
        XCTAssertEqual(unit.externalDecls.count, 1)
        switch unit.externalDecls[0] {
        case .functionDefinition(let def):
            XCTAssertEqual(def.compoundStatement.declaration.count, 1)
        default: XCTFail()
        }
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
            XCTAssertEqual(function.declarator.directDeclarator, .declaratorWithIdentifiers(.identifier("main"), .default([])))
            XCTAssertEqual(function.compoundStatement.statement.count, 1)
        default: XCTFail()
        }
    }
}
