import XCTest

import SwiftGraphQlTests

var tests = [XCTestCaseEntry]()
tests += ParserTests.allTests()
tests += LexerTests.allTests()
XCTMain(tests)
