//
//  Ast.swift
//  GraphQL
//
//  Created by Matt Gadda on 12/7/19.
//

// AST Types
enum TBD {}

public enum Value : Equatable  {
  case int(Int)
  case float(Float)
  case string(String)
  case boolean(Bool)
  case null
  case enumArm(String)
  case object([String:Value])
  case list([Value])
  case variable(String)
}

public struct Directive : Equatable  {
  public let name: String
  public let arguments: [Argument]
  public init(name: String, arguments: [Argument]) {
    self.name = name
    self.arguments = arguments
  }
}


public enum Type : Equatable  {
  case identity(String)
  indirect case list(Type)
  indirect case required(Type)
}

public struct VariableDefinition : Equatable  {
  public let name: String
  public let type: Type
  public let defaultValue: Value?
  public let directives: [Directive]
  public init(name: String, type: Type, defaultValue: Value?, directives: [Directive]) {
    self.name = name
    self.type = type
    self.defaultValue = defaultValue
    self.directives = directives
  }
}

public struct Argument : Equatable  {
  public let name: String
  public let value: Value
  // TODO: while is this required? 
  public init(name: String, value: Value) {
    self.name = name
    self.value = value
  }
}

// TODO: consider defining custom equality to ensure that
// only fields which differ by alias are different
public struct Field : Equatable  {
  public let alias: String?
  public let name: String
  public let arguments: [Argument]
  public let directives: [Directive]
  public let selectionSet: [Selection]
  public init(alias: String?, name: String, arguments: [Argument], directives: [Directive], selectionSet: [Selection]) {
    self.alias = alias
    self.name = name
    self.arguments = arguments
    self.directives = directives
    self.selectionSet = selectionSet
  }
}

public enum Selection : Equatable  {
  case field(Field)
  case fragmentSpread(String, [Directive])
  case inlineFragment(Type?, [Directive], [Selection])
}

public struct FragmentSpread : Equatable  {
  public let name: String
  public let directives: [Directive]
}

public struct FragmentDefinition : Equatable  {
  public let name: String
  public let typeCondition: Type // note: type system does not enforce that it's a named type here
  public let directives: [Directive]
  public let selectionSet: [Selection] // note: type system does not enforce that selection set doesn't contain duplicate fields
  public init(name: String, typeCondition: Type, directives: [Directive], selectionSet: [Selection]) {
    self.name = name
    self.typeCondition = typeCondition
    self.directives = directives
    self.selectionSet = selectionSet
  }
}

public enum OperationType {
  case query, subscription, mutation
}

public struct OperationDefinition : Equatable  {
  public let selectionSet: [Selection]
  public let operationType: OperationType
  public let name: String?
  public let variableDefinitions: [VariableDefinition]
  public let directives: [Directive]

  public init(_ selectionSet: [Selection], operationType: OperationType = .query, name: String? = .none, variableDefinitions: [VariableDefinition] = [], directives: [Directive] = []) {
    self.selectionSet = selectionSet
    self.operationType = operationType
    self.name = name
    self.variableDefinitions = variableDefinitions
    self.directives = directives
  }
}

public enum ExecutableDefinition : Equatable {
  case opDefinition(OperationDefinition)
  case fragmentDefinition(FragmentDefinition)
}

public typealias Document = [ExecutableDefinition]
