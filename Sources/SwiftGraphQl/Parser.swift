//
//  Parser.swift
//  GraphQL
//
//  Created by Matt Gadda on 12/5/19.
//
import SwiftParse

infix operator ~>: MultiplicationPrecedence

fileprivate func StreamTokenInt(t: StreamToken) -> Bool {
  if case .intValue = t { return true } else { return false }
}

fileprivate func StreamTokenFloat(t: StreamToken) -> Bool {
  if case .floatValue = t { return true } else { return false }
}

fileprivate func StreamTokenString(t: StreamToken) -> Bool {
  if case .stringValue = t { return true } else { return false }
}

fileprivate func StreamTokenBool(t: StreamToken) -> Bool {
  if case .booleanValue = t { return true } else { return false }
}

fileprivate func StreamTokenNull(t: StreamToken) -> Bool {
  if case .nullValue = t { return true } else { return false }
}

fileprivate func StreamTokenName(t: StreamToken) -> Bool {
  if case .name = t { return true } else { return false }
}

fileprivate func StreamTokenVariable(t: StreamToken) -> Bool {
  if case .variable = t { return true } else { return false }
}

fileprivate func StreamTokenDirective(t: StreamToken) -> Bool {
  if case .directive = t { return true } else { return false }
}

typealias StreamTokenParser<T> = ArrayParser<StreamToken, T>

public struct GraphQlDocumentParser {
  static let name = accept(StreamTokenName) ^^ { $0.asString! }
//  static var value: ArrayParser<StreamToken, Value> = placeholder

  // Scalar values
  static let intValue = accept(StreamTokenInt) ^^ { $0.asValue! }
  static let floatValue = accept(StreamTokenFloat) ^^ { $0.asValue! }
  static let stringValue = accept(StreamTokenString) ^^ { $0.asValue! }
  static let booleanValue = accept(StreamTokenBool) ^^ { $0.asValue! }
  static let nullValue = accept(StreamTokenNull) ^^ { $0.asValue! }
  static let enumValue = name ^^ { Value.enumArm($0) } // TODO: make this exclude nullValues and booleanValues
//
//  // List values
  static let emptyList = accept(StreamToken.leftBracket) ~ accept(StreamToken.rightBracket) ^^ { _ in [Value]() }
  static let valueList = value ~ (accept(StreamToken.comma) <~ value)*  ^^ { (first, rest) in [first] + rest }
  static let nonEmptyList = accept(StreamToken.leftBracket) <~ valueList ~> accept(StreamToken.rightBracket)
  static let listValue = emptyList | nonEmptyList ^^ { Value.list($0) }
//
//  // Object values
  static let emptyObject = accept(StreamToken.leftCurly) ~ accept(StreamToken.rightCurly) ^^ { _ in Value.object([String:Value]()) }
  static let keyValue = name ~ (accept(StreamToken.colon) <~ value)
  static let keyValueList = keyValue ~ (accept(StreamToken.comma) <~ keyValue)*  ^^ { (first, rest) in Value.object([String:Value](uniqueKeysWithValues: [first] + rest)) }
  static let nonEmptyObject = accept(StreamToken.leftCurly) <~ keyValueList ~> accept(StreamToken.rightCurly)
  static let objectValue = emptyObject | nonEmptyObject
//
//  // Directives
  static let directiveName = accept(StreamTokenDirective) ^^ { $0.asString! }
////  static var argument: StreamTokenParser<Argument> = placeholder
  static let directive = directiveName ~ arguments ^^ { (name, arguments) in
    Directive(name: name, arguments: arguments)
  }
//  static let directives = directive*
//
//  // Type references
//  static let namedType = name ^^ { Type.identity($0) }
//  static let listType = accept(StreamToken.leftBracket) <~ namedType ~> accept(StreamToken.rightBracket) ^^ { Type.list($0) }
//  static let nonNullType = (namedType ~> accept(StreamToken.exclamation)) | (listType ~> accept(StreamToken.exclamation)) ^^ { Type.required($0) }
//  static let type = namedType | listType | nonNullType
//
//  // Variable List Definitions
//  static let variable = accept(StreamTokenVariable) ^^ { $0.asString! }
//  static let variableType = type
//  static let variableDefinition = variable ~ variableType ~ value*? ~ directives ^^ { (name, varType, defaultValue, directives) -> VariableDefinition in
//    VariableDefinition(name: name, type: varType, defaultValue: defaultValue, directives: directives)
//  }
//  static let variableList = variableDefinition ~ (accept(StreamToken.comma) <~ variableDefinition)* ^^ { (first, rest) in [first] + rest }
//  static let variableDefinitions = accept(StreamToken.leftParen) <~ variableList ~> accept(StreamToken.rightParen)
//
//  static let variableAsValue = variable ^^ { Value.variable($0) }
  static let value = intValue | floatValue | stringValue | booleanValue | nullValue | enumValue
  static let constValue: StreamTokenParser<Value> = value | listValue | objectValue
//  static let nonConstValue = value | variableAsValue
//
//  // Arguments
  static let argument = name ~ accept(StreamToken.colon) ~ constValue ^^ { (name, _, value) in Argument(name: name, value: value) }
  // TODO: are empty argument lists allowed?
  static let argumentList = argument ~ (accept(StreamToken.comma) <~ argument)* ^^ { (first, rest) in [first] + rest }
  static let arguments = accept(StreamToken.leftParen) <~ argumentList ~> accept(StreamToken.rightParen)
//
//  // Fields and selection sets
//  static let alias = name ~> accept(StreamToken.colon)
//  static var field: () -> ArrayParser<StreamToken, Field> = {
//    alias*? ~ name ~ arguments ~ directives ~ selectionSet() ^^ { (alias, name, arguments, directives, selectionSet) in
//      Field(alias: alias, name: name, arguments: arguments, directives: directives, selectionSet: selectionSet)
//    }
//  }
//  static let fieldAsSelection = field() ^^ { Selection.field($0) }
//  // note: does not check that "on" is *not* used
//  static let fragmentSpread = accept(StreamToken.ellipsis) <~ name ~ directives ^^ { (name, directives) in
//    Selection.fragmentSpread(name, directives)
//  }
//  static let typeCondition = accept(StreamToken.name("on")) <~ type
//  static let selection: () -> StreamTokenParser<Selection> = { fieldAsSelection | fragmentSpread | inlineFragment }
//  static let selectionSet: () -> StreamTokenParser<[Selection]> = { accept(StreamToken.leftCurly) <~ selection()+ ~> accept(StreamToken.rightCurly) }
//
//  static let inlineFragment: () -> StreamTokenParser<Selection> = { accept(StreamToken.ellipsis) <~ typeCondition*? ~ directives ~ selectionSet() ^^ { (typeCondition, directives, selectionSet) in
//      Selection.inlineFragment(typeCondition, directives, selectionSet)
//    }
//  }
//
//
////  static let field = alias*? ~ name ~ arguments ~ directives ~ selectionSet ^^ { (alias, name, arguments, directives, selectionSet) in
////    Field(alias: alias, name: name, arguments: arguments, directives: directives, selectionSet: selectionSet)
////  }
//
//  // Operations
//  static let queryOptType = accept(StreamToken.name("query")) ^^ { _ in OperationType.query }
//  static let mutationOptType = accept(StreamToken.name("mutation")) ^^ { _ in OperationType.mutation }
//  static let subscriptionOptType = accept(StreamToken.name("subscription")) ^^ { _ in OperationType.subscription }
//  static let opType = queryOptType | mutationOptType | subscriptionOptType
//  static let simpleOperationDefinition = selectionSet() ^^ { OperationDefinition($0) }
//
//  static let fullOperationDefinition = opType ~ name*? ~ variableDefinitions ~ directives ~ selectionSet() ^^ { (opType, name, variableDefinitions, directives, selectionSet) in
//    OperationDefinition(selectionSet, operationType: opType, name: name, variableDefinitions: variableDefinitions, directives: directives)
//  }
//
//  static let opDefinition = simpleOperationDefinition | fullOperationDefinition
//  static let fragmentDefinition = accept(StreamToken.name("fragment")) <~ name ~ typeCondition ~ directives ~ selectionSet() ^^ { (name, typeCondition, directives, selectionSet) in
//    FragmentDefinition(name: name, typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
//  }
//  static let executableDefinition = (opDefinition ^^ { ExecutableDefinition.opDefinition($0) }) | (fragmentDefinition ^^ { ExecutableDefinition.fragmentDefinition($0)})
//  static let typeSystemDefinition: ArrayParser<StreamToken, TBD> = placeholder
//  static let typeSystemExt: ArrayParser<StreamToken, TBD> = placeholder
//  static let definition = executableDefinition// | typeSystemDefition | typeSystemExt
//  static let document = definition+
}

//public func GraphQlParser(source: String) throws -> Document {
//  let lexer = GraphQlLexer()
//  let (lexResult, _) = try lexer(Substring(source)).get()
//
//  let tokens = lexResult.filter { (token) -> Bool in
//    switch token {
//    case .whitespace: return false
//    default: return true
//    }
//  }
//
//  let parser = GraphQlDocumentParser.document
//  let result = parser(ArraySlice(tokens)).map { (doc, _ ) in doc }
//  if case let .failure(e) = result {
//    print(e.reason ?? "")
//    print(e.at)
//  }
//  return try result.get()
//}


