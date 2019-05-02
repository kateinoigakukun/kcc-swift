import Curry

enum ASTPhase: ParserPhase {
    typealias Collection = [Token]
}
typealias ASTParser<T> = Parser<ASTPhase, T>

public func parse(_ tokens: [Token]) throws -> TranslationUnit {
    return try parseTranslationUnit().parse(.root(tokens)).0
}

func parseTranslationUnit() -> ASTParser<TranslationUnit> {
    return TranslationUnit.init <^> many(parseExternalDeclaration())
}

func parseExternalDeclaration() -> ASTParser<ExternalDeclaration> {
    return
        (ExternalDeclaration.functionDefinition <^> parseFunctionDefinition())
            <|> (ExternalDeclaration.decl <^> parseDeclaration())
}

/// <function-definition> ::= {<declaration-specifier>}* <declarator> {<declaration>}* <compound-statement>
func parseFunctionDefinition() -> ASTParser<FunctionDefinition> {
    return curry(FunctionDefinition.init)
        <^> many(parseDeclarationSpecifier())
        <*> parseDeclarator()
        <*> many(parseDeclaration())
        <*> parseCompoundStatement()
}

func parseDeclarationSpecifier() -> ASTParser<DeclarationSpecifier> {
    return (DeclarationSpecifier.storageClassSpecifier <^> parseStorageClassSpecifier())
        <|> (DeclarationSpecifier.typeSpecifier <^> parseTypeSpecifier())
        <|> (DeclarationSpecifier.typeQualifier <^> parseTypeQualifier())
}

func parseDeclarator() -> ASTParser<Declarator> {
    return curry(Declarator.init)
        <^> orNil(parsePointer())
        <*> parseDirectDeclarator()
}


func parsePointer() -> ASTParser<Pointer> {
    return match(.multiply) *> (
        curry(Pointer.init)
            <^> many(parseTypeQualifier())
            <*> (Box.init <^> orNil(parsePointer()))
    )
}

// TODO
func parseDirectDeclarator() -> ASTParser<DirectDeclarator> {
    return choice(
        [
            match(.leftParen) *>
                (curry(DirectDeclarator.declarator) <^> parseDeclarator())
                <* match(.rightParen),
            curry(DirectDeclarator.declaratorWithIdentifiers)
                <^> mapIdentifier(DirectDeclarator.identifier) // TODO
                <*> (
                    match(.leftParen) *> parseParameterTypeList() <* match(.rightParen)
            ),
            curry(DirectDeclarator.identifier) <^> mapIdentifier(id),
        ]
    )
}

func parseParameterTypeList() -> ASTParser<ParameterTypeList> {
    return curry(ParameterTypeList.default) <^> parseParameterList()
        <|> .pure(.default([]))
}

func parseParameterList() -> ASTParser<ParameterList> {
    return cons
        <^> parseParameterDeclaration()
        <*> many(match(.comma) *> parseParameterDeclaration())
}

func parseParameterDeclaration() -> ASTParser<ParameterDeclaration> {
    return curry(ParameterDeclaration.init)
        <^> many(parseDeclarationSpecifier())
        <*> parseDeclarator()
}

func parseDeclaration() -> ASTParser<Declaration> {
    return curry(Declaration.init)
        <^> many1(parseDeclarationSpecifier())
        <*> (many(parseInitDeclarator()) <* match(.semicolon))
}


func parseStorageClassSpecifier() -> ASTParser<StorageClassSpecifier> {
    return mapIdentifier(StorageClassSpecifier.init)
}

func parseTypeSpecifier() -> ASTParser<TypeSpecifier> {
    return mapIdentifier(TypeSpecifier.init)
}

func parseTypeQualifier() -> ASTParser<TypeQualifier> {
    return mapIdentifier(TypeQualifier.init)
}

func parseInitDeclarator() -> ASTParser<InitDeclarator> {
    return curry(InitDeclarator.init)
        <^> parseDeclarator()
        <*> orNil(parseInitializer())
}

func parseInitializer() -> ASTParser<Initializer> {
    return (curry(Initializer.assignment) <^> parseAssignmentExpression())
        <|> curry(Initializer.initializerList) <^> parseInitializerList()
}

func parseInitializerList() -> ASTParser<[Initializer]> {
    return cons
        <^> (parseInitializer() <* match(.comma))
        <*> parseInitializerList()
}

func parseCompoundStatement() -> ASTParser<CompoundStatement> {
    return match(.leftBrace) *> (
        curry(CompoundStatement.init)
            <^> many(parseDeclaration())
            <*> many(parseStatement())
        ) <* match(.rightBrace)
}

func parseStatement() -> ASTParser<Statement> {
    return choice(
        [
            curry(Statement.compound) <^> parseCompoundStatement(),
            curry(Statement.expression) <^> parseExpressionStatement(),
            curry(Statement.jump) <^> parseJumpStatement(),
            curry(Statement.selection) <^> parseSelectionStatement(),
        ]
    )
}

func parseJumpStatement() -> ASTParser<JumpStatement> {
    return curry(JumpStatement.return)
        <^> match(.identifier("return"))
        *> orNil(parseExpression())
        <* match(.semicolon)
}

func parseSelectionStatement() -> ASTParser<SelectionStatement> {
    return curry(SelectionStatement.if)
        <^> match(.identifier("if")) *> match(.leftParen) *> parseExpression() <* match(.rightParen)
        <*> parseStatement()
}

func parseExpressionStatement() -> ASTParser<ExpressionStatement> {
    return curry(ExpressionStatement.init)
        <^> orNil(parseExpression()) <* match(.semicolon)
}

func parseExpression() -> ASTParser<Expression> {
    return curry(Expression.assignment) <^> parseAssignmentExpression()
}

func parseAssignmentExpression() -> ASTParser<AssignmentExpression> {
    return choice(
        [
            AssignmentExpression.unary <^> parseUnaryExpression(),
            curry(AssignmentExpression.assignment)
                <^> parseUnaryExpression()
                <*> parseAssignmentOperator()
                <*> parseAssignmentExpression()
        ]
    )
}

func parseUnaryExpression() -> ASTParser<UnaryExpression> {
    return UnaryExpression.postfix <^> parsePostfixExpression()
}

func parsePostfixExpression() -> ASTParser<PostfixExpression> {
    let primary = PostfixExpression.primary <^> parsePrimaryExpression()
    let functionCall = curry(PostfixExpression.functionCall)
        // TODO: Support recursive. Use parsePostFixExpression()
        <^> primary
        <*> (
            match(.leftParen)
                *> (
                    (cons
                        <^> parseAssignmentExpression()
                        <*> many(
                            match(.comma)
                                *> parseAssignmentExpression()
                        )
                    ) <|> .pure([])
                )
                <* match(.rightParen)
    )
    return choice([functionCall, primary])
}

// TODO: Use this
func parseArgumentExpressionList() -> ASTParser<[AssignmentExpression]> {
    return cons <^> parseAssignmentExpression()
        <*> many(match(.comma) *> parseAssignmentExpression())
}


func parsePrimaryExpression() -> ASTParser<PrimaryExpression> {
    return choice(
        [
            mapIdentifier(PrimaryExpression.identifier),
            PrimaryExpression.constant <^> parseConstant(),
            PrimaryExpression.string <^> string(),
        ]
    )
}

func parseConstant() -> ASTParser<Constant> {
    return choice(
        [
            Constant.integer <^> integer()
        ]
    )
}

func parseAssignmentOperator() -> ASTParser<AssignmentOperator> {
    return const(AssignmentOperator.equal) <^> match(.equal)
}

enum MatchError: Error {
    case notMatch(ASTParser<Token>.Input)
}

func mapToken<T>(_ f: @escaping (Token) -> T?) -> ASTParser<T> {
    return ASTParser { input in
        let head = input.collection[input.startIndex]
        guard let result = f(head) else {
            throw MatchError.notMatch(input)
        }
        let newIndex = input.collection.index(after: input.startIndex)
        let newInput = ASTParser<Token>.Input(previous: input, newIndex: newIndex)
        return (result, newInput)
    }
}

func match(_ token: Token) -> ASTParser<Token> {
    return mapToken({
        guard $0 == token else { return nil }
        return $0
    })
}
func string() -> ASTParser<String> {
    return mapToken {
        switch $0 {
        case .string(let string): return string
        default: return nil
        }
    }
}

func integer() -> ASTParser<Int> {
    return mapToken {
        switch $0 {
        case .integer(let integer): return integer
        default: return nil
        }
    }
}

func mapIdentifier<T>(_ f: @escaping (String) -> T?) -> ASTParser<T> {
    return mapToken {
        switch $0 {
        case .identifier(let identifier):
            return f(identifier)
        default: return nil
        }
    }
}

enum SatisfyPeekError: Error {
    case invalid
}

func satisfyPeek(_ f: @escaping (Token) -> Bool) -> ASTParser<Void> {
    return ASTParser { input in
        if f(input.collection[input.startIndex]) {
            return ((), input)
        } else {
            throw SatisfyPeekError.invalid
        }
    }
}
