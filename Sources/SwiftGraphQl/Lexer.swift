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
  static let sourceCharacterSet = CharacterSet(charactersIn: "\u{0020}"..."\u{FFFF}")
    .union(CharacterSet.init(charactersIn: "\u{0009}\u{000A}\u{000D}"))
  static let sourceCharacter = match(sourceCharacterSet)
    
  static let whitespace = (" " | "\n" | "\t")+ ^^ { _ in StreamToken.whitespace }

  static let digits = CharacterSet.decimalDigits+ ^^ { String($0) }
  
  static let fracPart = "." <~ digits
  static let optSign = "-"*? ^^ { $0.map { String($0)} ?? "" }
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

  static let escapedCharacter = "\\" ~ CharacterSet(charactersIn: "\"\\/bfnrt") ^^ {
    (slash, c) in "\(slash)\(c)"
  }

  static let hexDigit = match(CharacterSet(charactersIn: "abcdefABCDEF0123456789"))
    
  static let unicodeCharacter = hexDigit ~ hexDigit ~ hexDigit ~ hexDigit ^^ { (d1, d2, d3, d4) in
    String([d1, d2, d3, d4])
  }
  static let escapedUnicode = match("\\u") ~ unicodeCharacter ^^ { (u, c) in u + c }
  
  static let linefeed = match(element: Character("\u{000A}"))
  static let carriageReturn = match(element: Character("\u{000D}")) ~> lookAhead(not(linefeed))
  static let crlf = match(element: Character("\u{000D}\u{000A}"))
  static let lineTerminator = linefeed | carriageReturn | crlf
     
  static let invalidStringChars =
    CharacterSet(charactersIn: "\"\\") |
    lineTerminator
  
  static let stringCharacter =
    ((sourceCharacter & not(invalidStringChars)) ^^ { String($0) }) |
    escapedUnicode |
    escapedCharacter
   
  static let blockQuote = match(prefix: "\"\"\"") ^^ { String($0) }
  static let escapedBlockQuote = match(prefix: "\\\"\"\"") ^^ { String($0) }
  
  static let blockStringCharacter =
    (and(map(sourceCharacter) { String($0) }, not(blockQuote | escapedBlockQuote)))
    // | escapedBlockQuote // TODO: should this case be supported?
  
  static let emptyDoubleQuotedStringValue = "\"\"" ~> lookAhead(not("\""))              ^^ { _ in StreamToken.stringValue("") }
  static let doubleQuotedStringValue = "\"" <~ stringCharacter* ~> "\""                 ^^ { StreamToken.stringValue($0.joined()) }
  static let blockQuotedStringValue = blockQuote <~ blockStringCharacter* ~> blockQuote ^^ { StreamToken.stringValue($0.joined())}
  // blockQuotedStringValue must come before doubleQuotedStringValue
  static let stringValue = emptyDoubleQuotedStringValue | blockQuotedStringValue | doubleQuotedStringValue

  static let leftCurly = "{" ^^ { _ in StreamToken.leftCurly }
  static let rightCurly = "}" ^^ { _ in StreamToken.rightCurly }
  static let curlies = leftCurly | rightCurly

  static let rightBracket = "]" ^^ { _ in StreamToken.rightBracket }
  static let leftBracket = "[" ^^ { _ in StreamToken.leftBracket }
  static let brackets = leftBracket | rightBracket

  static let rightParen = ")" ^^ { _ in StreamToken.rightParen }
  static let leftParen = "(" ^^ { _ in StreamToken.leftParen }
  static let parens = leftParen | rightParen

  static let colon = ":" ^^ { _ in StreamToken.colon }
  static let comma = "," ^^ { _ in StreamToken.comma }
  static let ellipsis = "..." ^^ { _ in StreamToken.ellipsis }
  static let assignment = "=" ^^ { _ in StreamToken.assignment }
  static let exclamation = "!" ^^ { _ in StreamToken.exclamation }

  static let lowerAlpha = match(CharacterSet(charactersIn: "a"..."z"))
  static let upperAlpha = match(CharacterSet(charactersIn: "A"..."Z"))
  static let nameStart = match(element: Character("_")) | upperAlpha | lowerAlpha
  static let nameCharacter = nameStart | match(CharacterSet(charactersIn: "0"..."9"))
  static let name = nameStart ~ nameCharacter* ^^ { StreamToken.name(String($0) + String($1)) }
  static let variable = "$" <~ nameCharacter+ ^^ { StreamToken.variable(String($0)) }
  static let directive = "@" <~ nameCharacter+ ^^ { StreamToken.directive(String($0)) }

  static let booleanValue = "true" | "false" ^^ { bool in
      StreamToken.booleanValue(String(bool) == "true")
  }
  
  static let nullValue = "null" ^^ { _ in StreamToken.nullValue }
  static let values = intValue | floatValue | stringValue | nullValue | booleanValue
  static let punctuation = assignment | exclamation | colon | comma | ellipsis
  static let allParens = parens | curlies | brackets
  static let punctuationAndBrackets = punctuation | allParens

  static let query = "query" ^^ { _ in StreamToken.query }
  static let mutation = "mutation" ^^ { _ in StreamToken.mutation }
  static let subscription = "subscription" ^^ { _ in StreamToken.subscription }
  static let on = "on" ^^ { _ in StreamToken.on }
  static let fragment = "fragment" ^^ { _ in StreamToken.fragment }
  static let keywords = (query | mutation | subscription | on | fragment) ~> either(lookAhead(CharacterSet(charactersIn: " {")), eof)
  
  static let lexer1 = whitespace | punctuation | keywords | values
  static let lexer2 = name | variable | directive | punctuationAndBrackets
  static let lexer = (lexer1 | lexer2)+
}
  
