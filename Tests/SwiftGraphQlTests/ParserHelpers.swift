//
//  ParserTestHelpers.swift
//  SwiftGraphQlTests
//
//  Created by Matt Gadda on 12/10/19.
//

import XCTest
@testable import SwiftGraphQl
@testable import SwiftParse

protocol ParserHelpers {
  func assertParsed<T: Equatable & Emptiness, U: Equatable>(
    _ parser: Parser<T, U>,
    input: T,
    val: U,
    remaining: T,
    message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  )
}

extension ParserHelpers {
  func assertParsed<T: Equatable & Emptiness, U: Equatable>(
        _ parser: Parser<T, U>,
    input: T,
    val: U,
    remaining: T = T.emptyValue,
    message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    switch parser(input) {
    case let .success(s):
        XCTAssertEqual(s.0, val, "val differs", file: file, line: line)
        XCTAssertEqual(s.1, remaining, "remaining differs", file: file, line: line)
    case let .failure(e):
      XCTFail("Failed to parse at \(e.at). Reason: \(e.reason ?? "")", file: file, line: line)
    }
  }

  func assertNotParsed<T: Equatable & Emptiness, U: Equatable>(
    _ parser: Parser<T, U>,
    input: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    switch parser(input) {
    case let .success(parsed, remaining):
      XCTFail("Succeeded at parsing \(parsed) but should have failed. Remaining = \(remaining)", file: file, line: line)
    case .failure: return
    }
  }
}

protocol Emptiness {
  var isEmpty: Bool { get }
  static var emptyValue: Self { get }
}

extension Substring : Emptiness {
  static var emptyValue: Self { "" }
}
extension ArraySlice : Emptiness {
  static var emptyValue: Self { ArraySlice([]) }
}
