//
//  Parser.swift
//  Brainfuck
//
//  Created by Matt Gadda on 11/25/19.
//

import SwiftParse

infix operator ~>: MultiplicationPrecedence

// TODO: rename to LexicalToken
internal enum StreamToken : Equatable {
  // Whitespace
  case whitespace

  // Literals
  case intValue(Int)
  case floatValue(Float)
  case stringValue(String)
  case booleanValue(Bool)
  case nullValue

  // Punctuation
  case leftBracket
  case rightBracket
  case leftCurly
  case rightCurly
  case leftParen
  case rightParen
  case colon
  case comma
  case ellipsis
  case assignment
  case exclamation

  // Entities
  case name(String)
  case variable(String)
  case directive(String)

  public var asValue: Value? {
    switch self {
    case let .intValue(i): return Value.int(i)
    case let .floatValue(f): return Value.float(f)
    case let .stringValue(s): return Value.string(s)
    case let .booleanValue(b): return Value.boolean(b)
    case .nullValue: return Value.null
    default: return .none
    }
  }

  public var asString: String? {
    switch self {
    case let .name(s): return s
    case let .variable(v): return v
    case let .directive(d): return d
    default: return .none
    }
  }
}

internal func GraphQlLexer() -> StringParser<[StreamToken]> {
  // A Lexer is defined as a parser that converts String into an Array of StreamTokens
  let tab = accept("\t")
  let newline = accept("\n")
  let space = accept(" ")
  let whitespace = (space | newline | tab)+ ^^ { _ in StreamToken.whitespace }

  let digit: StringParser<String> = { source in
    acceptIf(source) { $0 >= "0" && $0 <= "9" }
  }

  let fracPart = accept(".") <~ digit+
  let optSign = accept("-")*?
  let intString = optSign ~ digit+ ^^ { ($0.0 ?? "") + $0.1.joined() }
  let intLiteral = intString ^^ { Int($0)! }
  let floatLiteral = intString ~ fracPart*?  ^^ { parsed -> Float in
    switch parsed {
    case let (integral, .none):
      return Float(integral)!
    case let (integral, .some(fracStr)):
      let floatStr = "\(integral).\(fracStr)"
      return Float(floatStr)!
    }
  }

  let intValue = intLiteral ^^ { StreamToken.intValue($0) }
  let floatValue = floatLiteral ^^ { StreamToken.floatValue($0)}

  let escapedCharacter = accept("\\") ~ accept(oneOf: "\"\\/bfnrt") ^^ { (slash, c) in slash + c }

  func hexDigit(source: Substring) -> ParseResult<Substring, String> {
    acceptIf(source, fn: { (ch: Substring.Element) -> Bool in
      (ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F")
    })
  }

  let unicodeCharacter = map(hexDigit ~ hexDigit ~ hexDigit ~ hexDigit) { (d1, d2, d3, d4) in [d1,d2,d3,d4].joined() }
  let escapedUnicode = accept("\\u") ~ unicodeCharacter ^^ { (u, c) in u + c }
  let stringCharacter = reject(allOf: "\"\\\n") | escapedCharacter | escapedUnicode

  let stringQuote = accept("\"")
  let doubleQuotedStringValue = stringQuote <~ stringCharacter* ~> stringQuote ^^ { StreamToken.stringValue($0.joined()) }

  let blockQuote = accept("\"\"\"")
  let blockQuotedStringValue = blockQuote <~ reject(character: "\"")* ~> blockQuote ^^ { StreamToken.stringValue($0.joined()) }
  let stringValue = blockQuotedStringValue | doubleQuotedStringValue


  let leftCurly = accept("{") ^^ { _ in StreamToken.leftCurly }
  let rightCurly = accept("}") ^^ { _ in StreamToken.rightCurly }
  let curlies = leftCurly | rightCurly

  let rightBracket = accept("]") ^^ { _ in StreamToken.rightBracket }
  let leftBracket = accept("[") ^^ { _ in StreamToken.leftBracket }
  let brackets = leftBracket | rightBracket

  let rightParen = accept(")") ^^ { _ in StreamToken.rightParen }
  let leftParen = accept("(") ^^ { _ in StreamToken.leftParen }
  let parens = leftParen | rightParen

  let colon = accept(":") ^^ { _ in StreamToken.colon }
  let comma = accept(",") ^^ { _ in StreamToken.comma }
  let ellipsis = accept("...") ^^ { _ in StreamToken.ellipsis }
  let assignment = accept("=") ^^ { _ in StreamToken.assignment }
  let exclamation = accept("!") ^^ { _ in StreamToken.exclamation }

  let nameCharacter = accept(range: "a"..."z") | accept(range: "A"..."Z") | accept(range: "0"..."9")
  let name = nameCharacter+ ^^ { StreamToken.name($0.joined()) }

  let variable = accept("$") <~ nameCharacter+ ^^ { StreamToken.variable($0.joined()) }
  let directive = accept("@") <~ nameCharacter+ ^^ { StreamToken.directive($0.joined()) }

  let booleanValue = accept("true") | accept("false") ^^ { bool in StreamToken.booleanValue(bool == "true") }
  let nullValue = accept("null") ^^ { _ in StreamToken.nullValue }
  let values = intValue | floatValue | stringValue | nullValue | booleanValue
  let punctuation = assignment | exclamation | colon | comma | ellipsis
  let allParens = parens | curlies | brackets
  let punctuationAndBrackets = punctuation | allParens

  let lexer = (whitespace | punctuation | values | name | variable | directive | punctuationAndBrackets)+
  return lexer
}
  
