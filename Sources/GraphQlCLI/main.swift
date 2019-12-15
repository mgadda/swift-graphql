//
//  main.swift
//  SwiftGraphQl
//
//  Created by Matt Gadda on 12/14/19.
//

import SwiftGraphQl
import Foundation

func printHelp() {
  print("usage: graphql-cli parse [filename]")
}

guard CommandLine.arguments.count >= 3 else {
  print("not enough arguments")
  exit(1)
}

guard CommandLine.arguments[1] == "parse" else {
  print("unknown command")
  exit(1)
}

do {
  let source = try String(contentsOfFile: CommandLine.arguments[2])
  _ = try parseGraphQl(source: source)
} catch {
  print(error)
  exit(1)
}
