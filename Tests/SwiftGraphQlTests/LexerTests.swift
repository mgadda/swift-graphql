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
  func testLineTerminator() {
    assertParsed(GraphQlLexer.lineTerminator, input: "\n", val: "\n")
    assertParsed(GraphQlLexer.lineTerminator, input: "\r\n", val: "\r\n")
    assertParsed(GraphQlLexer.lineTerminator, input: "\r", val: "\r")
  }
  func testStringCharacter() {
    assertParsed(GraphQlLexer.stringCharacter, input: "a", val: "a")
    assertParsed(GraphQlLexer.stringCharacter, input: "\\u1234", val: "\\u1234")
    
    assertNotParsed(GraphQlLexer.stringCharacter, input: "\\")
    assertNotParsed(GraphQlLexer.stringCharacter, input: "\"")
    
  }
  func testDoubleQuotedStringValue() {
    let input = "\"a string with\\n\\tsome special characters: \\u1234\""
    assertParsed(GraphQlLexer.stringValue, input: input, val: StreamToken.stringValue("a string with\\n\\tsome special characters: \\u1234"))
  }
  func testBlockStringCharacter() {
    assertParsed(GraphQlLexer.blockStringCharacter, input: "a", val: "a")
    assertParsed(GraphQlLexer.blockStringCharacter, input: "\"", val: "\"")
    assertNotParsed(GraphQlLexer.blockStringCharacter, input: "\"\"\"")
    // TODO: should this case be supported?
    //assertParsed(GraphQlLexer.blockStringCharacter, input: "\\\"\"\"", val: "\\\"\"\"")
  }
  func testBlockQuotedStringValue() {
    assertParsed(GraphQlLexer.stringValue, input: "\"\"\"\"\"\"", val: StreamToken.stringValue(""))
    
    let input = """
\"\"\"How sweet to be a Cloud
Floating in the "Blue!"
Every \\little\\ cloud
Always sings aloud!\"\"\"
"""
    
    assertParsed(GraphQlLexer.stringValue, input: input, val: StreamToken.stringValue("How sweet to be a Cloud\nFloating in the \"Blue!\"\nEvery \\little\\ cloud\nAlways sings aloud!"))
  }

  func testNameValue() {
    let lexer = GraphQlLexer.name

    assertParsed(lexer, input: "field", val: StreamToken.name("field"))
    assertParsed(lexer, input: "Field", val: StreamToken.name("Field"))
    assertParsed(lexer, input: "_field", val: StreamToken.name("_field"))
    assertParsed(lexer, input: "__typename", val: StreamToken.name("__typename"))
    assertParsed(lexer, input: "a1", val: StreamToken.name("a1"))
    assertParsed(lexer, input: "e", val: StreamToken.name("e"))

    assertNotParsed(lexer, input: "é")
    assertNotParsed(lexer, input: "1")
  }

  func testNameKeywordDisambiguation() {
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
      ("testUnicodeCharacter", testUnicodeCharacter),
      ("testLineTerminator", testLineTerminator),
      ("testStringCharacter", testStringCharacter),
      ("testDoubleQuotedStringValue", testDoubleQuotedStringValue),
      ("testBlockStringCharacter", testBlockStringCharacter),
      ("testBlockQuotedStringValue", testBlockQuotedStringValue),
      ("testNameValue", testNameValue),
      ("testNameKeywordDisambiguation", testNameKeywordDisambiguation)
  ]
}
