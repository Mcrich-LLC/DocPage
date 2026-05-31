//
//  CompileCommand.swift
//  DocPage
//
//  Created by Morris Richman on 5/30/26.
//

import Foundation
import ArgumentParser
import SwiftCommand

enum RunErrors: LocalizedError {
    case swiftNotFound
    case compileFailed(Int32?)
    
    var localizedDescription: String {
        switch self {
        case .swiftNotFound:
            return "Swift is not installed on your system. We don't know how you're running this, but make sure you have Swift installed and in your path."
        case .compileFailed(let code):
            guard let code else {
                return "Compilation failed"
            }
            return "Compilation failed with code \(code)"
        }
    }
}

struct CompileCommand: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "compile",
        abstract: "Compiles your markdown file into a DocC json file"
    )
    @Argument(help: "The path to your markdown file")
    var path: String
    
    @Option(name: [.short, .customLong("output")], help: "The path to the output your file")
    var outputPath: String?
    
    func run() throws {
        let inputFileURL = URL(filePath: path)
        guard inputFileURL.pathExtension.lowercased() == "md" else {
            throw ValidationError("File must be a markdown file")
        }
        
        let templateURL = try makeTemplate()
        
        // Copy markdown file into template directory
        try FileManager.default.copyItem(at: inputFileURL, to: templateURL.appending(path: "Sources/Template/Documentation.docc/Documentation.md"))
        
        // Compile DocC
        guard let swift = Command.findInPath(withName: "swift") else {
            throw RunErrors.swiftNotFound
        }
        let compileStatus = try swift.setCWD(.init(templateURL.path(percentEncoded: false))).addArguments(Self.docCGenerateCommandArguments).wait()
        
        guard compileStatus.terminatedSuccessfully else {
            throw RunErrors.compileFailed(compileStatus.terminationSignal)
        }
        
        print("Documentation Built 🎉")
        print("Extracting your JSON file...")
        
        // Extract File
        let jsonURL = templateURL.appending(path: "docs/data/documentation/template/documentation.json")
        let outputURL = if let outputPath {
            URL(filePath: NSString(string: outputPath).expandingTildeInPath)
        } else {
            URL(filePath: inputFileURL.lastPathComponent)
        }
        try FileManager.default.copyItem(at: jsonURL, to: outputURL)
        
        print("Cleaning Up 🧹")
        try FileManager.default.removeItem(at: templateURL)
        print("Done! 🎉")
        print("Generated json at \(outputURL.path)")
    }
    
    /// Makes a DocPage template in a temporary directory.'
    ///
    /// - Returns: The `URL` of said temporary directory template.
    private func makeTemplate() throws -> URL {
        // Make tmp folder
        let tmpURL = URL.temporaryDirectory.appendingPathComponent("doc-page_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: true)
        
        // Make `Package.swift` file
        try Self.packageSwift.write(to: tmpURL.appending(path: "Package.swift"), atomically: true, encoding: .utf8)
        
        // Make `Template.swift` file
        let sourcesFolder = tmpURL.appending(path: "Sources/Template")
        try FileManager.default.createDirectory(at: sourcesFolder, withIntermediateDirectories: true)
        try Self.templateSwift.write(to: sourcesFolder.appending(path: "Template.swift"), atomically: true, encoding: .utf8)
        
        // Make DocC archive
        let docCArchiveURL = sourcesFolder.appending(path: "Documentation.docc")
        try FileManager.default.createDirectory(at: docCArchiveURL, withIntermediateDirectories: true)
        
        return tmpURL
    }
}

// MARK: - Commands
private extension CompileCommand {
    static let docCGenerateCommandArguments = [
        "package",
        "--allow-writing-to-directory", "./docs",
        "generate-documentation", "--target", "Template",
        "--disable-indexing",
        "--transform-for-static-hosting",
        "--hosting-base-path", "/",
        "--experimental-skip-synthesized-symbols",
        "--output-path", "./docs"
    ]
}

// MARK: - Template Files
private extension CompileCommand {
    static let packageSwift = """
        // swift-tools-version: 5.9
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        let package = Package(
            name: "Template",
            dependencies: [
                .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.3.0"),
            ],
            targets: [
                // Targets are the basic building blocks of a package, defining a module or a test suite.
                // Targets can depend on other targets in this package and products from dependencies.
                .target(name: "Template"),
            ]
        )
        """
    static let templateSwift = """
        // The Swift Programming Language
        // https://docs.swift.org/swift-book

        // This does nothing
        """
}
