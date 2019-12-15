//
//  main.swift
//  SwiftGraphQL CLI
//
//  Created by Matt Gadda on 12/14/19.
//

import SwiftGraphQl
import Foundation

func printError(_ value: Any) {
  FileHandle.standardError.write(("\(value)").data(using: .utf8)!)
}

func printHelp() {
  printError("""
usage: graphql-cli parse [filename]
Use `-` in place of `[filename]` to read from stdin.
""")
}

if CommandLine.arguments.count >= 2 && (CommandLine.arguments[1] == "--help" || CommandLine.arguments[1] == "-h") {
  printHelp()
  exit(0)
}

guard CommandLine.arguments.count >= 3 else {
  printError("error: not enough arguments\n")
  printHelp()
  exit(1)
}

guard CommandLine.arguments[1] == "parse" else {
  printError("error: unknown command")
  printHelp()
  exit(1)
}

let filename = CommandLine.arguments[2]


do {
  if filename == "-" {
    let source = FileHandle.standardInput.readDataToEndOfFile()
    _ = try parseGraphQl(source: String(data: source, encoding: .utf8)!)
  } else {
    let source = try String(contentsOfFile: filename)
    _ = try parseGraphQl(source: source)
  }
  
} catch {
  printError(error)
  exit(1)
}
