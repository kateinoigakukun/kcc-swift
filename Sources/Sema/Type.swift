indirect enum Type {
    case int
    case void
    case array(Type)
    case function(input: Type, output: Type)
}

typealias DeclContext = [String: Type]
