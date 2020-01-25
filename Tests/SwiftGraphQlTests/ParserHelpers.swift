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
  func assertParsed<T: Collection & Emptiness, U: Equatable>(
    _ parser: StandardParser<T, U>,
    input: T,
    val: U,
    remaining: AnyCollection<T.Element>,
    message: @autoclosure () -> String,
    file: StaticString,
    line: UInt
  )  where T.Element: Equatable
}

extension ParserHelpers {  
  func assertParsed<T: Collection & Emptiness, U: Equatable>(
    _ parser: StandardParser<T, U>,
    input: T,
    val: U,
    remaining: AnyCollection<T.Element> = AnyCollection(T.emptyValue),
    message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) where T.Element: Equatable {
    switch parser(AnyCollection(input)) {
    case let .success(s):
        XCTAssertEqual(s.0, val, "val differs", file: file, line: line)
        XCTAssertEqual(s.1, remaining, "remaining differs", file: file, line: line)
    case let .failure(e):
      XCTFail("Failed to parse at \(e.at). Reason: \(e.reason ?? "")", file: file, line: line)
    }
  }

  func assertNotParsed<T: Collection & Emptiness, U: Equatable>(
    _ parser: StandardParser<T, U>,
    input: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    switch parser(AnyCollection(input)) {
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

extension AnyCollection : Emptiness {
  static var emptyValue: Self { AnyCollection([]) }
}

extension AnyCollection : Equatable where Element: Equatable {
  public static func ==(lhs: AnyCollection<Element>, rhs: AnyCollection<Element>) -> Bool {
    lhs.elementsEqual(rhs) { $0 == $1 }
  }
}

extension String : Emptiness {
  static var emptyValue: Self { "" }
}

extension Array : Emptiness {
  static var emptyValue: Self { [] }
}
