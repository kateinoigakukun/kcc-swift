public indirect enum Type: Equatable {
    case int
    case void
    case array(Type)
    case function(input: [Type], output: Type)
}

public typealias DeclContext = [String: Type]
