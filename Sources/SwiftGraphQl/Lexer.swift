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

  // Keywords
  case query
  case mutation
  case subscription
  case on
  case fragment
  
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

struct GraphQlLexer {
  // A Lexer is defined as a parser that converts String into an Array of StreamTokens
  static let tab = accept("\t")
  static let newline = accept("\n")
  static let space = accept(" ")
  static let whitespace = (space | newline | tab)+ ^^ { _ in StreamToken.whitespace }

  static let digit: StringParser<String> = { source in
    acceptIf(source) { $0 >= "0" && $0 <= "9" }
  }

  static let fracPart = accept(".") <~ digit+ ^^ { $0.joined() }
  static let optSign = accept("-")*?
  static let intString = optSign ~ digit+ ^^ { ($0.0 ?? "") + $0.1.joined() }
  static let intLiteral = intString ^^ { Int($0)! }
  static let floatLiteral = intString ~ fracPart*?  ^^ { parsed -> Float in
    switch parsed {
    case let (integral, .none):
      return Float(integral)!
    case let (integral, .some(fracStr)):
      let floatStr = "\(integral).\(fracStr)"
      return Float(floatStr)!
    }
  }

  static let intValue = intLiteral ^^ { StreamToken.intValue($0) }
  static let floatValue = floatLiteral ^^ { StreamToken.floatValue($0)}

  static let escapedCharacter = accept("\\") ~ accept(oneOf: "\"\\/bfnrt") ^^ { (slash, c) in slash + c }

  static func hexDigit(source: Substring) -> ParseResult<Substring, String> {
    acceptIf(source, fn: { (ch: Substring.Element) -> Bool in
      (ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F")
    })
  }

  static let unicodeCharacter = map(hexDigit ~ hexDigit ~ hexDigit ~ hexDigit) { (d1, d2, d3, d4) in [d1,d2,d3,d4].joined() }
  static let escapedUnicode = accept("\\u") ~ unicodeCharacter ^^ { (u, c) in u + c }
  static let stringCharacter = reject(allOf: "\"\\\n") | escapedCharacter | escapedUnicode

  static let stringQuote = accept("\"")
  static let doubleQuotedStringValue = stringQuote <~ stringCharacter* ~> stringQuote ^^ { StreamToken.stringValue($0.joined()) }

  static let blockQuote = accept("\"\"\"")
  // Allow for less than 3 consecutive instances of '"'
  static let blockQuotedStringValue = blockQuote <~ reject(character: "\"")* ~> blockQuote ^^ { StreamToken.stringValue($0.joined()) }
  static let stringValue = blockQuotedStringValue | doubleQuotedStringValue


  static let leftCurly = accept("{") ^^ { _ in StreamToken.leftCurly }
  static let rightCurly = accept("}") ^^ { _ in StreamToken.rightCurly }
  static let curlies = leftCurly | rightCurly

  static let rightBracket = accept("]") ^^ { _ in StreamToken.rightBracket }
  static let leftBracket = accept("[") ^^ { _ in StreamToken.leftBracket }
  static let brackets = leftBracket | rightBracket

  static let rightParen = accept(")") ^^ { _ in StreamToken.rightParen }
  static let leftParen = accept("(") ^^ { _ in StreamToken.leftParen }
  static let parens = leftParen | rightParen

  static let colon = accept(":") ^^ { _ in StreamToken.colon }
  static let comma = accept(",") ^^ { _ in StreamToken.comma }
  static let ellipsis = accept("...") ^^ { _ in StreamToken.ellipsis }
  static let assignment = accept("=") ^^ { _ in StreamToken.assignment }
  static let exclamation = accept("!") ^^ { _ in StreamToken.exclamation }

  static let nameCharacter = accept(range: "a"..."z") | accept(range: "A"..."Z") | accept(range: "0"..."9") | accept("_")
  static let name = nameCharacter+ ^^ { StreamToken.name($0.joined()) }

  static let variable = accept("$") <~ nameCharacter+ ^^ { StreamToken.variable($0.joined()) }
  static let directive = accept("@") <~ nameCharacter+ ^^ { StreamToken.directive($0.joined()) }

  static let booleanValue = accept("true") | accept("false") ^^ { bool in StreamToken.booleanValue(bool == "true") }
  static let nullValue = accept("null") ^^ { _ in StreamToken.nullValue }
  static let values = intValue | floatValue | stringValue | nullValue | booleanValue
  static let punctuation = assignment | exclamation | colon | comma | ellipsis
  static let allParens = parens | curlies | brackets
  static let punctuationAndBrackets = punctuation | allParens

  static let query = accept("query") ^^ { _ in StreamToken.query }
  static let mutation = accept("mutation") ^^ { _ in StreamToken.mutation }
  static let subscription = accept("subscription") ^^ { _ in StreamToken.subscription }
  static let on = accept("on") ^^ { _ in StreamToken.on }
  static let fragment = accept("fragment") ^^ { _ in StreamToken.fragment }
  static let keywords = (query | mutation | subscription | on | fragment) ~> either(lookAhead(accept(oneOf: " {")), eof)
  
  static let lexer = (whitespace | punctuation | keywords | values | name | variable | directive | punctuationAndBrackets)+
}
  
