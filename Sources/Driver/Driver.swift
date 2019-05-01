import Foundation
import Parser
import CodeGen

public class Driver {
    let arguments: [String]
    let isVerbose: Bool
    public init(arguments: [String]) {
        self.arguments = arguments
        self.isVerbose = arguments.contains("-v")
    }
    public func run() {
        guard arguments.count > 2 else {
            help()
            return
        }
        let subcommand = arguments[1]
        let path = arguments[2]
        do {
            let content = try String(contentsOfFile: path)
            let tokens = try lex(content)
            let unit = try parse(tokens)
            let code = CodeGenerator().generate(unit)
            switch subcommand {
            case "compile":
                let output = arguments[3]
                try compile(code, output: output)
            case "gen":
                fputs(code, stdout)
            default: help()
            }
        } catch {
            fputs(String(describing: error), stderr)
        }
    }

    func help() {
        let help = """
            Usage: kcc <subcommand>
            Subcommands:
                compile <input> <output>    Compile source file and emit executable file
                gen <input>                 Compile source file and emit asm
            """
        fputs(help, stdout)
    }

    func compile(_ code: String, output: String) throws {
        let tmpFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("asm").path
        try code.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        if isVerbose { fputs("Code was generated to \(tmpFile)", stdout) }
        nasm(tmpFile)
        let objectFilePath = tmpFile
            .split(separator: ".").dropLast()
            .joined(separator: ".") + ".o"
        ld(objectFile: objectFilePath, output: output)
    }

    func nasm(_ file: String) {
        let ps = Process()
        ps.launchPath = "/usr/local/bin/nasm"
        ps.arguments = ["-f", "macho64", file]
        ps.launch()
        ps.waitUntilExit()
    }

    func ld(objectFile: String, output: String) {
        let ps = Process()
        ps.launchPath = "/usr/bin/ld"
        ps.arguments = ["-macosx_version_min", "10.14", "-lSystem", "-o", output, objectFile]
        ps.launch()
        ps.waitUntilExit()
    }
}
