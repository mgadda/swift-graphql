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

typealias StreamTokenParser<T> = StandardParser<[StreamToken], T>

func match(_ token: StreamToken) -> StandardParser<[StreamToken], StreamToken> {
  return { match(element: token)($0) }
}

struct GraphQlDocumentParser {
  static let name = match(StreamTokenName) ^^ { $0.asString! }

  // Scalar values
  static let intValue = match(StreamTokenInt) ^^ { $0.asValue! }
  static let floatValue = match(StreamTokenFloat) ^^ { $0.asValue! }
  static let stringValue = match(StreamTokenString) ^^ { $0.asValue! }
  static let booleanValue = match(StreamTokenBool) ^^ { $0.asValue! }
  static let nullValue = match(StreamTokenNull) ^^ { $0.asValue! }
  static let enumValue = name ^^ { Value.enumArm($0) } // TODO: make this exclude nullValues and booleanValues

  // List values
  static let emptyList = match(StreamToken.leftBracket) ~ match(StreamToken.rightBracket) ^^ { _ in [Value]() }
  static let valueList: () -> StreamTokenParser<[Value]> = { value ~ (match(StreamToken.comma) <~ value)*  ^^ { (first, rest) in [first] + rest } }
  static let nonEmptyList = match(StreamToken.leftBracket) <~ valueList() ~> match(StreamToken.rightBracket)
  static let listValue = emptyList | nonEmptyList ^^ { Value.list($0) }

  // Object values
  static let emptyObject = match(StreamToken.leftCurly) ~ match(StreamToken.rightCurly) ^^ { _ in Value.object([String:Value]()) }
  static let keyValue: () -> StreamTokenParser<(String, Value)> = { name ~ (match(StreamToken.colon) <~ value) }
  static let keyValueList = keyValue() ~ (match(StreamToken.comma) <~ keyValue())*  ^^ { (first, rest) in Value.object([String:Value](uniqueKeysWithValues: [first] + rest)) }
  static let nonEmptyObject = match(StreamToken.leftCurly) <~ keyValueList ~> match(StreamToken.rightCurly)
  static let objectValue = emptyObject | nonEmptyObject

  // Directives
  static let directiveName = match(StreamTokenDirective) ^^ { $0.asString! }
  //  static var argument: StreamTokenParser<Argument> = placeholder
  static let directive = directiveName ~ arguments*? ^^ { (name, arguments) in
    Directive(name: name, arguments: arguments ?? [])
  }
  static let directives = directive*

  // Type references
  static let namedType = name ^^ { Type.named($0) }
  static let listType = match(StreamToken.leftBracket) <~ namedType ~> match(StreamToken.rightBracket) ^^ { Type.list($0) }
  static let nonNullType = (namedType ~> match(StreamToken.exclamation)) | (listType ~> match(StreamToken.exclamation)) ^^ { Type.required($0) }
  // The order here matters:
  static let type = nonNullType | listType | namedType

  // Variable List Definitions
  static let variable = match(StreamTokenVariable) ^^ { $0.asString! }
  static let variableType = type
  static let variableDefinition = variable ~> match(StreamToken.colon) ~ variableType ~ (match(StreamToken.assignment) <~ value)*? ~ directives ^^ { (name, varType, defaultValue, directives) -> VariableDefinition in
    VariableDefinition(name: name, type: varType, defaultValue: defaultValue, directives: directives)
  }
  static let variableList = variableDefinition ~ (match(StreamToken.comma) <~ variableDefinition)* ^^ { (first, rest) in [first] + rest }
  static let variableDefinitions = match(StreamToken.leftParen) <~ variableList ~> match(StreamToken.rightParen)

  static let variableAsValue = variable ^^ { Value.variable($0) }
  // TODO: value definition is not adherent to spec because
  // it does not differentiate between const and non-const
  // values
  static let value1 = intValue | floatValue | stringValue | booleanValue
  static let value2 = nullValue | enumValue | listValue | objectValue | variableAsValue
  static let value = value1 | value2
//  static let constValue: StreamTokenParser<Value> = value | listValue | objectValue
//  static let nonConstValue = value | variableAsValue

  // Arguments
  static let argument = name ~ match(StreamToken.colon) ~ value ^^ { (name, _, value) in Argument(name: name, value: value) }
  // TODO: are empty argument lists allowed?
  static let argumentList = argument ~ (match(StreamToken.comma) <~ argument)* ^^ { (first, rest) in [first] + rest }
  static let arguments = match(StreamToken.leftParen) <~ argumentList ~> match(StreamToken.rightParen)

  // Fields and selection sets
  static let alias = name ~> match(StreamToken.colon)
  static var field: () -> StreamTokenParser<Field> = {
    alias*? ~ name ~ arguments*? ~ directives ~ selectionSet()*? ^^ { (alias, name, arguments, directives, selectionSet) in
      Field(named: name, alias: alias, arguments: arguments ?? [], directives: directives, selectionSet: selectionSet ?? [])
    }
  }
  static let fieldAsSelection = field() ^^ { Selection.field($0) }
  static let fragmentSpread = match(StreamToken.ellipsis) <~ name ~ directives ^^ { (name, directives) in
    Selection.fragmentSpread(name, directives)
  }
  static let typeCondition = match(StreamToken.on) <~ type
  // inlineFragment must come before fragmentSpread because "... on" is more specific than "... Foo"
  static let selection = fieldAsSelection | inlineFragment() | fragmentSpread
  static let selectionSet: () -> StreamTokenParser<[Selection]> = { match(StreamToken.leftCurly) <~ selection+ ~> match(StreamToken.rightCurly) }

  static let inlineFragment: () -> StreamTokenParser<Selection> = { match(StreamToken.ellipsis) <~ typeCondition*? ~ directives ~ selectionSet() ^^ { (typeCondition, directives, selectionSet) in
      Selection.inlineFragment(typeCondition, directives, selectionSet)
    }
  }

  // Operations
  static let queryOptType = match(StreamToken.query) ^^ { _ in OperationType.query }
  static let mutationOptType = match(StreamToken.mutation) ^^ { _ in OperationType.mutation }
  static let subscriptionOptType = match(StreamToken.subscription) ^^ { _ in OperationType.subscription }
  static let opType = queryOptType | mutationOptType | subscriptionOptType
  static let simpleOperationDefinition = selectionSet() ^^ { OperationDefinition($0) }
  static let fullOperationDefinition = opType ~ name*? ~ variableDefinitions*? ~ directives ~ selectionSet() ^^ { (opType, name, variableDefinitions, directives, selectionSet) in
    OperationDefinition(selectionSet, operationType: opType, name: name, variableDefinitions: variableDefinitions ?? [], directives: directives)
  }
//
  static let opDefinition = simpleOperationDefinition | fullOperationDefinition
  static let fragmentDefinition = match(StreamToken.fragment) <~ name ~ typeCondition ~ directives ~ selectionSet() ^^ { (name, typeCondition, directives, selectionSet) in
    FragmentDefinition(name: name, typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
  }
  static let executableDefinition = (opDefinition ^^ { ExecutableDefinition.opDefinition($0) }) | (fragmentDefinition ^^ { ExecutableDefinition.fragmentDefinition($0)})
//  static let typeSystemDefinition: ArrayParser<StreamToken, TBD> = placeholder
//  static let typeSystemExt: ArrayParser<StreamToken, TBD> = placeholder
  static let definition = executableDefinition// | typeSystemDefition | typeSystemExt
  static let document = definition+
}

public func parseGraphQl(source: String) throws -> Document {  
  let (lexResult, _) = try GraphQlLexer.lexer(AnyCollection(source)).get()

  let tokens = lexResult.filter { (token) -> Bool in
    switch token {
    case .whitespace: return false
    default: return true
    }
  }

  let parser = GraphQlDocumentParser.document
  let result = parser(AnyCollection(tokens)).map { (doc, _ ) in doc }
  if case let .failure(e) = result {
    print(e.reason ?? "")
    print(e.at)
  }
  return try result.get()
}


