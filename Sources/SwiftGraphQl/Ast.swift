//
//  Ast.swift
//  GraphQL
//
//  Created by Matt Gadda on 12/7/19.
//

enum TBD {}

public enum Definition : Equatable {
  case executable(ExecutableDefinition)
  case type(TypeSystemDefinition)
  case `extension`
}
public enum ExecutableDefinition : Equatable {
  case operation(OperationDefinition)
  case fragment(FragmentDefinition)
}

public typealias Document = [Definition]


// Operational types -----

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
  case named(String)
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
// only fields which differ by alias are considered different
public struct Field : Equatable  {
  public let alias: String?
  public let name: String
  public let arguments: [Argument]
  public let directives: [Directive]
  public let selectionSet: [Selection]
  public init(
    named: String,
    alias: String? = nil,
    arguments: [Argument] = [],
    directives: [Directive] = [],
    selectionSet: [Selection] = []
  ) {
    self.name = named
    self.alias = alias
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

// Type system types ----------

public struct InputValue : Equatable {
  public let description: String?
  public let name: String
  public let type: Type
  public let defaultValue: Value?
  public let directives: [Directive]
}

public struct FieldDefinition : Equatable {
  public let description: String?
  public let name: String
  public let arguments: [InputValue]
  public let type: Type
  public let directives: [Directive]
}

public struct ScalarTypeDefinition : Equatable {
  public let description: String?
  public let name: String
  public let directives: [Directive]
}

public struct ObjectTypeDefinition : Equatable {
  public let description: String?
  public let name: String
  public let interfaces: [Type]?
  public let fields: [FieldDefinition]
  public let directives: [Directive]
}

public struct InterfaceTypeDefinition : Equatable {}
public struct UnionTypeDefinition : Equatable {}
public struct EnumTypeDefinition : Equatable {}
public struct InputObjectTypeDefinition : Equatable {}


public enum TypeDefinition : Equatable {
  case scalar(ScalarTypeDefinition)
  case object(ObjectTypeDefinition)
  case interface(InterfaceTypeDefinition)
  case union(UnionTypeDefinition)
  case `enum`(EnumTypeDefinition)
  case inputObject(InputObjectTypeDefinition)
}
public enum TypeSystemDefinition : Equatable {
  case schema(directives: [Directive], rootTypes: [OperationType:Type])
  case type
  case directive
}
