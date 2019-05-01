import Parser

class TypeChecker {
    func solve(_ unit: TranslationUnit) {
        for externalDecl in unit.externalDecls {
            solve(externalDecl)
        }
    }

    func solve(_ externalDecl: ExternalDeclaration) {
        switch externalDecl {
        case .functionDefinition(let functionDefinition):
            solve(functionDefinition)
        case .decl:
            unimplemented()
        }
    }

    func solve(_ functionDefinition: FunctionDefinition) {
        functionDefinition.declarator.directDeclarator
    }
}

func unimplemented() -> Never {
    fatalError("unimplemented")
}
