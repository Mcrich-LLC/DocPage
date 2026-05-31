// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct DocPage: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "docpage",
        abstract: "Generate a single page of documentation",
        subcommands: [
            CompileCommand.self
        ]
    )
    static let configDir = URL.homeDirectory.appending(path: ".docpage")
}
