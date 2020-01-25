import XCTest
@testable import SwiftGraphQl
import SwiftParse

infix operator ~>: MultiplicationPrecedence

final class LexerTests: XCTestCase, ParserHelpers {
  func testIntLiteral() {
    assertParsed(GraphQlLexer.intLiteral, input: "1", val: 1)
    assertParsed(GraphQlLexer.intLiteral, input: "-1", val: -1)
  }
  func testFloatLiteral() {
    assertParsed(GraphQlLexer.floatLiteral, input: "1.4", val: 1.4)
    assertParsed(GraphQlLexer.floatLiteral, input: "-1.4", val: -1.4)
    assertParsed(GraphQlLexer.floatLiteral, input: "1", val: 1.0)
  }
  func testEscapedCharacter() {
    assertParsed(GraphQlLexer.escapedCharacter, input: "\\b", val: "\\b")
  }
  func testUnicodeCharacter() {
    assertParsed(GraphQlLexer.escapedUnicode, input: "\\uaf09", val: "\\uaf09")
  }
  func testDoubleQuotedStringValue() {
    let input = "\"a string with\\n\\tsome special characters: \\u1234\""
    assertParsed(GraphQlLexer.doubleQuotedStringValue, input: input, val: StreamToken.stringValue("a string with\\n\\tsome special characters: \\u1234"))
  }
  func testBlockQuotedStringValue() {
    let input = """
\"\"\"How sweet to be a Cloud
Floating in the Blue!
Every little cloud
Always sings aloud!\"\"\"
"""
    assertParsed(GraphQlLexer.blockQuotedStringValue, input: input, val: StreamToken.stringValue("How sweet to be a Cloud\nFloating in the Blue!\nEvery little cloud\nAlways sings aloud!"))
  }
  
  func testNameKeywordDisambiuation() {
    let lexer = GraphQlLexer.keywords | GraphQlLexer.name
    
    assertParsed(lexer, input: "query_field", val: StreamToken.name("query_field"))
    assertParsed(lexer, input: "queryfield", val: StreamToken.name("queryfield"))
    assertParsed(lexer, input: "query {", val: StreamToken.query, remaining: AnyCollection(" {"))
    assertParsed(lexer, input: "query", val: StreamToken.query)
    
  }
  
  static var allTests = [
      ("testIntLiteral", testIntLiteral),
      ("testFloatLiteral", testFloatLiteral),
      ("testEscapedCharacter", testEscapedCharacter),
      ("testEscapedCharacter", testEscapedCharacter),
      ("testUnicodeCharacter", testUnicodeCharacter),
      ("testDoubleQuotedStringValue", testDoubleQuotedStringValue),
      ("testBlockQuotedStringValue", testBlockQuotedStringValue)
  ]
}
