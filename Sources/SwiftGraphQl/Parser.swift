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

internal func documentParser() -> ArrayParser<StreamToken, Document> {
  let name = accept(StreamTokenName) ^^ { $0.asString! }
  var value: ArrayParser<StreamToken, Value> = placeholder

  // Scalar values
  let intValue = accept(StreamTokenInt) ^^ { $0.asValue! }
  let floatValue = accept(StreamTokenFloat) ^^ { $0.asValue! }
  let stringValue = accept(StreamTokenString) ^^ { $0.asValue! }
  let booleanValue = accept(StreamTokenBool) ^^ { $0.asValue! }
  let nullValue = accept(StreamTokenNull) ^^ { $0.asValue! }
  let enumValue = name ^^ { Value.enumArm($0) } // TODO: make this exclude nullValues and booleanValues

  // List values
  let emptyList = accept(StreamToken.leftBracket) ~ accept(StreamToken.rightBracket) ^^ { _ in [Value]() }
  let valueList = value ~ (accept(StreamToken.comma) <~ value)*  ^^ { (first, rest) in [first] + rest }
  let nonEmptyList = accept(StreamToken.leftBracket) <~ valueList ~> accept(StreamToken.rightBracket)
  let listValue = emptyList | nonEmptyList ^^ { Value.list($0) }

  // Object values
  let emptyObject = accept(StreamToken.leftCurly) ~ accept(StreamToken.rightCurly) ^^ { _ in Value.object([String:Value]()) }
  let keyValue = name ~ (accept(StreamToken.colon) <~ value)
  let keyValueList = keyValue ~ (accept(StreamToken.comma) <~ keyValue)*  ^^ { (first, rest) in Value.object([String:Value](uniqueKeysWithValues: [first] + rest)) }
  let nonEmptyObject = accept(StreamToken.leftCurly) <~ keyValueList ~> accept(StreamToken.rightCurly)
  let objectValue = emptyObject | nonEmptyObject

  // Directives
  let directiveName = accept(StreamTokenDirective) ^^ { $0.asString! }
  var argument: ArrayParser<StreamToken, Argument> = placeholder
  let directive = directiveName ~ argument* ^^ { (name, arguments) in        
    Directive(name: name, arguments: arguments)
  }
  let directives = directive*

  // Type references
  let namedType = name ^^ { Type.identity($0) }
  let listType = accept(StreamToken.leftBracket) <~ namedType ~> accept(StreamToken.rightBracket) ^^ { Type.list($0) }
  let nonNullType = (namedType ~> accept(StreamToken.exclamation)) | (listType ~> accept(StreamToken.exclamation)) ^^ { Type.required($0) }
  let type = namedType | listType | nonNullType

  // Variable List Definitions
  let variable = accept(StreamTokenVariable) ^^ { $0.asString! }
  let variableType = type
  let variableDefinition = variable ~ variableType ~ value*? ~ directives ^^ { (name, varType, defaultValue, directives) -> VariableDefinition in
    VariableDefinition(name: name, type: varType, defaultValue: defaultValue, directives: directives)
  }
  let variableList = variableDefinition ~ (accept(StreamToken.comma) <~ variableDefinition)* ^^ { (first, rest) in [first] + rest }
  let variableDefinitions = accept(StreamToken.leftParen) <~ variableList ~> accept(StreamToken.rightParen)

  let variableAsValue = variable ^^ { Value.variable($0) }
  value = intValue | floatValue | stringValue | booleanValue | nullValue | enumValue
  let constValue: ArrayParser<StreamToken, Value> = value | listValue | objectValue
  let nonConstValue = value | variableAsValue

  // Arguments
  argument = name ~ accept(StreamToken.colon) ~ constValue ^^ { (name, _, value) in Argument(name: name, value: value) }
  let argumentList = argument ~ (accept(StreamToken.comma) <~ argument)* ^^ { (first, rest) in [first] + rest }
  let arguments = accept(StreamToken.leftParen) <~ argumentList ~> accept(StreamToken.rightParen)

  // Fields and selection sets
  let alias = name ~> accept(StreamToken.colon)
  var field: ArrayParser<StreamToken, Field> = placeholder
  let fieldAsSelection = field ^^ { Selection.field($0) }
  // note: does not check that "on" is *not* used
  let fragmentSpread = accept(StreamToken.ellipsis) <~ name ~ directives ^^ { (name, directives) in
    Selection.fragmentSpread(name, directives)
  }
  let typeCondition = accept(StreamToken.name("on")) <~ type
  var selectionSet: ArrayParser<StreamToken, [Selection]> = placeholder
  let inlineFragment = accept(StreamToken.ellipsis) <~ typeCondition*? ~ directives ~ selectionSet ^^ { (typeCondition, directives, selectionSet) in
    Selection.inlineFragment(typeCondition, directives, selectionSet)
  }
  let selection = fieldAsSelection | fragmentSpread | inlineFragment
  selectionSet = accept(StreamToken.leftCurly) <~ selection+ ~> accept(StreamToken.rightCurly)
  field = alias*? ~ name ~ arguments ~ directives ~ selectionSet ^^ { (alias, name, arguments, directives, selectionSet) in
    Field(alias: alias, name: name, arguments: arguments, directives: directives, selectionSet: selectionSet)
  }

  // Operations
  let queryOptType = accept(StreamToken.name("query")) ^^ { _ in OperationType.query }
  let mutationOptType = accept(StreamToken.name("mutation")) ^^ { _ in OperationType.mutation }
  let subscriptionOptType = accept(StreamToken.name("subscription")) ^^ { _ in OperationType.subscription }
  let opType = queryOptType | mutationOptType | subscriptionOptType
  let simpleOperationDefinition = selectionSet ^^ { OperationDefinition($0) }
  let fullOperationDefinition = opType ~ name*? ~ variableDefinitions ~ directives ~ selectionSet ^^ { (opType, name, variableDefinitions, directives, selectionSet) in
    OperationDefinition(selectionSet, operationType: opType, name: name, variableDefinitions: variableDefinitions, directives: directives)
  }
  let opDefinition = fullOperationDefinition | simpleOperationDefinition
  let fragmentDefinition = accept(StreamToken.name("fragment")) <~ name ~ typeCondition ~ directives ~ selectionSet ^^ { (name, typeCondition, directives, selectionSet) in
    FragmentDefinition(name: name, typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
  }
  let executableDefinition = (opDefinition ^^ { ExecutableDefinition.opDefinition($0) }) | (fragmentDefinition ^^ { ExecutableDefinition.fragmentDefinition($0)})
//  let typeSystemDefinition = placeholder
//  let typeSystemExt = placeholder
  let definition = executableDefinition// | typeSystemDefition | typeSystemExt
  let document = definition+
  return document
}

public func GraphQlParser(source: String) -> Document? {
  let lexer = GraphQlLexer()
  guard let (tokens, remaining) = lexer(Substring(source)) else {
    return nil
  }
  let parser = documentParser()
  guard let (doc, _) = parser(ArraySlice(tokens)) else {
    return nil
  }
  return doc
}
