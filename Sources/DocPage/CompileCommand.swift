//
//  CompileCommand.swift
//  DocPage
//
//  Created by Morris Richman on 5/30/26.
//

import Foundation
import ArgumentParser
import SwiftCommand
import ZIPFoundation

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

struct CompileCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "compile",
        abstract: "Compiles your markdown file into a DocC json file"
    )
    @Argument(help: "The path to your markdown file")
    var path: String
    
    @Option(name: [.short, .customLong("output")], help: "The path to the output your file")
    var outputPath: String?
    
    @Flag(name: .long, help: "Use this to automatically open a preview after compilation")
    var preview: Bool = false
    
    func run() async throws {
        #if !os(macOS)
        guard !preview else {
            throw ValidationError("Preview is only available on macOS")
        }
        #endif
        
        let inputFileURL = URL(filePath: path)
        guard inputFileURL.pathExtension.lowercased() == "md" else {
            throw ValidationError("File must be a markdown file")
        }
        
        print("Creating Template...")
        let templateURL = try makeTemplate()
        
        // Copy markdown file into template directory
        try FileManager.default.copyItem(at: inputFileURL, to: templateURL.appending(path: "Sources/Template/Documentation.docc/Documentation.md"))
        
        print("Template Made🎉")
        print()
        print("Compiling your documentation...")
        // Compile DocC
        guard let swift = Command.findInPath(withName: "swift") else {
            throw RunErrors.swiftNotFound
        }
        let compileStatus = try swift.setCWD(.init(templateURL.path(percentEncoded: false))).addArguments(Self.docCGenerateCommandArguments).wait()
        
        guard compileStatus.terminatedSuccessfully else {
            throw RunErrors.compileFailed(compileStatus.terminationSignal)
        }
        
        print("Documentation Built 🎉")
        print()
        print("Extracting your JSON file...")
        
        // Extract File
        let jsonURL = templateURL.appending(path: "docs/data/documentation/template/documentation.json")
        let outputURL = if let outputPath {
            URL(filePath: NSString(string: outputPath).expandingTildeInPath)
        } else {
            URL(filePath: inputFileURL.deletingPathExtension().lastPathComponent.appending(".json"))
        }
        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.copyItem(at: jsonURL, to: outputURL)
        
        print("Cleaning Up...")
        try FileManager.default.removeItem(at: templateURL)
        if !preview {
            print("Done! 🎉")
        }
        print("Generated json at \(outputURL.path)")
        
        if preview {
            print()
            print("Starting Preview...")
            try await openPreview(for: outputURL)
        }
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
    
    private func openPreview(for json: URL) async throws {
        let articleReaderAppURL = DocPage.configDir.appending(path: "DocC Article Viewer.app")
        if !FileManager.default.fileExists(atPath: articleReaderAppURL.path(percentEncoded: false)) {
            print("Article Viewer not found, downloading...")
            let zipURL = ProcessInfo.processInfo.environment["PREVIEW_ZIP_URL"] ?? "https://github.com/Mcrich-LLC/DocPage/releases/latest/downloadarticle-preview.zip"
            guard let zipURL = URL(string: zipURL) else {
                throw URLError(.badURL)
            }
            let zipFileURL = DocPage.configDir.appending(path: "article-preview.zip")
            
            let (data, _) = try await URLSession.shared.data(from: zipURL)
            
            try? FileManager.default.createDirectory(at: DocPage.configDir, withIntermediateDirectories: true)
            try data.write(to: zipFileURL)
            
            try FileManager.default.unzipItem(at: zipFileURL, to: articleReaderAppURL.deletingLastPathComponent())
            print("Download complete 🎉")
            print("")
        } else {
            print("Article Viewer found")
        }
        
        print("Opening preview for: \(json.lastPathComponent)")
        let app = Command(executablePath: .init(articleReaderAppURL.appending(path: "Contents/MacOS/DocC Article Viewer").path(percentEncoded: false)))
            .addArguments(["--preview", json.absoluteString])
        
        _ = try app.spawn()
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
