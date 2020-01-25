//
//  Parser.swift
//  Brainfuck
//
//  Created by Matt Gadda on 11/25/19.
//

import SwiftParse
import Foundation

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
  static let tab = match("\t")
  static let newline = match("\n")
  static let space = match(" ")
  static let whitespace = (space | newline | tab)+ ^^ { _ in StreamToken.whitespace }

  static let digits = match(CharacterSet.decimalDigits)+ ^^ { String($0) }
  
  static let fracPart = match(".") <~ digits
  static let optSign = match("-")*? ^^ { $0.map { String($0)} ?? "" }
  static let intString = optSign ~ digits ^^ { $0 + $1 }
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

  static let escapedCharacter = match("\\") ~ match(CharacterSet(charactersIn: "\"\\/bfnrt")) ^^ {
    (slash, c) in "\(slash)\(c)"
  }

  static let hexDigit = match(CharacterSet(charactersIn: "abcdefABCDEF0123456789"))
    
  static let unicodeCharacter = hexDigit ~ hexDigit ~ hexDigit ~ hexDigit ^^ { (d1, d2, d3, d4) in
    String([d1, d2, d3, d4])
  }
  static let escapedUnicode = match("\\u") ~ unicodeCharacter ^^ { (u, c) in u + c }
  static let invalidStringChars = reject(anyOf: "\"\\\n") ^^ { String($0) }
  static let stringCharacter = invalidStringChars | escapedCharacter | escapedUnicode
  
  static let stringQuote = match(element: Character("\""))
  static let doubleQuotedStringValue = stringQuote <~ stringCharacter* ~> stringQuote ^^ { x in
    StreamToken.stringValue(x.joined())
  }

  static let blockQuote = match(prefix: "\"\"\"")
  // Allow for less than 3 consecutive instances of '"'
  static let blockQuotedStringValue = blockQuote <~ reject(element: Character("\""))* ~> blockQuote ^^ { StreamToken.stringValue(String($0)) }
  static let stringValue = blockQuotedStringValue | doubleQuotedStringValue

  static let leftCurly = match("{") ^^ { _ in StreamToken.leftCurly }
  static let rightCurly = match("}") ^^ { _ in StreamToken.rightCurly }
  static let curlies = leftCurly | rightCurly

  static let rightBracket = match("]") ^^ { _ in StreamToken.rightBracket }
  static let leftBracket = match("[") ^^ { _ in StreamToken.leftBracket }
  static let brackets = leftBracket | rightBracket

  static let rightParen = match(")") ^^ { _ in StreamToken.rightParen }
  static let leftParen = match("(") ^^ { _ in StreamToken.leftParen }
  static let parens = leftParen | rightParen

  static let colon = match(":") ^^ { _ in StreamToken.colon }
  static let comma = match(",") ^^ { _ in StreamToken.comma }
  static let ellipsis = match("...") ^^ { _ in StreamToken.ellipsis }
  static let assignment = match("=") ^^ { _ in StreamToken.assignment }
  static let exclamation = match("!") ^^ { _ in StreamToken.exclamation }

  static let nameStart = match(CharacterSet.alphanumerics)
  static let nameCharacter = nameStart | match(element: Character("_"))
  static let name = nameStart ~ nameCharacter* ^^ { StreamToken.name(String($0) + String($1)) }
  static let variable = match("$") <~ nameCharacter+ ^^ { StreamToken.variable(String($0)) }
  static let directive = match("@") <~ nameCharacter+ ^^ { StreamToken.directive(String($0)) }

  static let booleanValue =
    match("true") |
    match("false") ^^ { bool in
      StreamToken.booleanValue(String(bool) == "true")
  }
  
  static let nullValue = match("null") ^^ { _ in StreamToken.nullValue }
  static let values = intValue | floatValue | stringValue | nullValue | booleanValue
  static let punctuation = assignment | exclamation | colon | comma | ellipsis
  static let allParens = parens | curlies | brackets
  static let punctuationAndBrackets = punctuation | allParens

  static let query = match("query") ^^ { _ in StreamToken.query }
  static let mutation = match("mutation") ^^ { _ in StreamToken.mutation }
  static let subscription = match("subscription") ^^ { _ in StreamToken.subscription }
  static let on = match("on") ^^ { _ in StreamToken.on }
  static let fragment = match("fragment") ^^ { _ in StreamToken.fragment }
  static let keywords = (query | mutation | subscription | on | fragment) ~> either(lookAhead(match(CharacterSet(charactersIn: " {"))), eof)
  
  static let lexer = (whitespace | punctuation | keywords | values | name | variable | directive | punctuationAndBrackets)+
}
  
