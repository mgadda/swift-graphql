import XCTest
@testable import SwiftGraphQl
import SwiftParse

final class ParserTests: XCTestCase, ParserHelpers {
  func testName() {
    assertParsed(GraphQlDocumentParser.name,
                 input: [.name("test")],
                 val: "test")
  }
  func testIntValue() {
    assertParsed(GraphQlDocumentParser.intValue,
                 input: [StreamToken.intValue(0)],
                 val: Value.int(0))
  }
  func testFloatValue() {
    assertParsed(GraphQlDocumentParser.floatValue,
                 input: [StreamToken.floatValue(1.5)],
                 val: Value.float(1.5))
  }
  func testStringValue() {
    assertParsed(GraphQlDocumentParser.stringValue,
                 input: [StreamToken.stringValue("test")],
                 val: Value.string("test"))
  }
  func testBooleanValue() {
    assertParsed(GraphQlDocumentParser.booleanValue,
                 input: [StreamToken.booleanValue(false)],
                 val: Value.boolean(false))
  }
  func testNullValue() {
    assertParsed(GraphQlDocumentParser.nullValue,
                 input: [StreamToken.nullValue],
                 val: Value.null)
  }
  func testEnumValue() {
    assertParsed(GraphQlDocumentParser.enumValue,
                 input: [.name("test")],
                 val: Value.enumArm("test"))
  }
  func testEmptyList() {
    assertParsed(GraphQlDocumentParser.emptyList,
                 input: [StreamToken.leftBracket,
                         StreamToken.rightBracket],
                 val: [])
  }
  func testValueListOne() {
    assertParsed(GraphQlDocumentParser.valueList(),
                 input: [StreamToken.intValue(0)],
                 val: [Value.int(0)])
  }
  func testValueListTwo() {
    assertParsed(GraphQlDocumentParser.valueList(),
                 input: [
                   StreamToken.intValue(0),
                   StreamToken.comma,
                   StreamToken.intValue(1)
                 ],
                 val: [Value.int(0), Value.int(1)])
  }
  func testNonEmptyList() {
    assertParsed(GraphQlDocumentParser.nonEmptyList,
                 input: [
                    StreamToken.leftBracket,
                    StreamToken.intValue(0),
                    StreamToken.comma,
                    StreamToken.intValue(1),
                    StreamToken.rightBracket
                 ],
                 val: [
                   Value.int(0),
                   Value.int(1)
                 ])
  }
  func testListValue() {
    assertParsed(GraphQlDocumentParser.listValue,
                 input: [
                   StreamToken.leftBracket,
                   StreamToken.rightBracket
                 ],
                 val: Value.list([]))
                
    assertParsed(GraphQlDocumentParser.listValue,
                 input: [
                    StreamToken.leftBracket,
                    StreamToken.intValue(0),
                    StreamToken.comma,
                    StreamToken.intValue(1),
                    StreamToken.rightBracket
                 ],
                 val: Value.list([
                   Value.int(0),
                   Value.int(1)
                 ]))
  }
  func testEmptyObject() {
    assertParsed(GraphQlDocumentParser.emptyObject,
                 input: [
                  StreamToken.leftCurly,
                  StreamToken.rightCurly
                 ],
                 val: Value.object([String:Value]()))
  }
  func testKeyValueList() {
    assertParsed(GraphQlDocumentParser.keyValueList,
                 input: [
                  StreamToken.name("key"),
                  StreamToken.colon,
                  StreamToken.stringValue("value"),
                  StreamToken.comma,
                  StreamToken.name("key2"),
                  StreamToken.colon,
                  StreamToken.stringValue("value2")
                 ],
                 val: Value.object([
                  "key": Value.string("value"),
                  "key2": Value.string("value2")
                 ]))
    
  }
  
  func testObjectValue() {
    assertParsed(GraphQlDocumentParser.objectValue,
                 input: [StreamToken.leftCurly, StreamToken.rightCurly],
                 val: Value.object([String:Value]()))
    
    assertParsed(GraphQlDocumentParser.objectValue,
                 input: [
                  StreamToken.leftCurly,
                  StreamToken.name("key"),
                  StreamToken.colon,
                  StreamToken.stringValue("value"),
                  StreamToken.rightCurly
                 ],
                 val: Value.object([
                  "key": Value.string("value"),
                 ]))
  }
  func testDirectiveName() {
    assertParsed(GraphQlDocumentParser.directiveName,
                 input: [StreamToken.directive("test")],
                 val: "test")
  }
  func testArgument() {
    assertParsed(GraphQlDocumentParser.argument,
                 input: [
                  StreamToken.name("name"),
                  StreamToken.colon,
                  StreamToken.stringValue("value")
                 ],
                 val: Argument(name: "name", value: Value.string("value")))
  }
  func testArgumentList() {
    assertParsed(GraphQlDocumentParser.argument,
                 input: [
                  StreamToken.name("name"),
                  StreamToken.colon,
                  StreamToken.stringValue("value")
                 ],
                 val: Argument(name: "name", value: Value.string("value")))
  }
  
  func testConstValue() {
    assertParsed(
      GraphQlDocumentParser.value,
      input: [StreamToken.intValue(0)],
      val: Value.int(0))
    
    assertParsed(
      GraphQlDocumentParser.value,
      input: [
        StreamToken.leftBracket,
        StreamToken.rightBracket
      ],
      val: Value.list([]))
    
    assertParsed(
      GraphQlDocumentParser.value,
        input: [
          StreamToken.leftCurly,
          StreamToken.rightCurly
        ],
        val: Value.object([String:Value]()))
  }
  
  func testArguments() {
    assertParsed(
      GraphQlDocumentParser.arguments,
      input: [
        StreamToken.leftParen,
        StreamToken.name("test"),
        StreamToken.colon,
        StreamToken.intValue(0),
        StreamToken.rightParen],
      val: [Argument(name: "test", value: Value.int(0))])
  }
  
  func testDirective() {
    // @test
    assertParsed(
      GraphQlDocumentParser.directive,
      input: [
       StreamToken.directive("test")],
      val: Directive(name: "test", arguments: []))
            
    // @test(key: 0)
    assertParsed(
      GraphQlDocumentParser.directive,
      input: [
        StreamToken.directive("test"),
        StreamToken.leftParen,
        StreamToken.name("key"),
        StreamToken.colon,
        StreamToken.intValue(0),
        StreamToken.rightParen],
      val: Directive(name: "test", arguments: [Argument(name: "key", value: Value.int(0))]))
  }
  
  func testNamedType() {
    // Test
    assertParsed(GraphQlDocumentParser.namedType,
                 input: [StreamToken.name("Test")],
                 val: Type.named("Test"))
  }
  func testListType() {
    // [Test]
    assertParsed(GraphQlDocumentParser.listType,
                 input: [
                  StreamToken.leftBracket,
                  StreamToken.name("Test"),
                  StreamToken.rightBracket],
                 val: Type.list(Type.named("Test")))
  }
  func testNonNullType() {
    // Test!
    assertParsed(GraphQlDocumentParser.nonNullType,
                 input: [
                  StreamToken.name("Test"),
                  StreamToken.exclamation],
                 val: Type.required(Type.named("Test")))
  }
  func testVariable() {
    // $var
    assertParsed(GraphQlDocumentParser.variable,
                 input: [StreamToken.variable("var")],
                 val: "var")
  }
  func testVariableDefinition() {
    // var: Type
    assertParsed(GraphQlDocumentParser.variableDefinition,
                 input: [
                  StreamToken.variable("var"),
                  StreamToken.colon,
                  StreamToken.name("String")],
                 val: VariableDefinition(
                  name: "var",
                  type: Type.named("String"),
                  defaultValue: nil,
                  directives: []))
        
    // var: Type = "test"
    assertParsed(GraphQlDocumentParser.variableDefinition,
                 input: [
                  StreamToken.variable("var"),
                  StreamToken.colon,
                  StreamToken.name("String"),
                  StreamToken.assignment,
                  StreamToken.stringValue("test")],
                 val: VariableDefinition(
                  name: "var",
                  type: Type.named("String"),
                  defaultValue: Value.string("test"),
                  directives: []))
    
    // var: Type @directive
    assertParsed(GraphQlDocumentParser.variableDefinition,
                 input: [
                  StreamToken.variable("var"),
                  StreamToken.colon,
                  StreamToken.name("String"),
                  StreamToken.directive("directive")],
                 val: VariableDefinition(
                  name: "var",
                  type: Type.named("String"),
                  defaultValue: nil,
                  directives: [Directive(name: "directive", arguments: [])]))
  }
  func testVariableDefinitions() {
    assertParsed(GraphQlDocumentParser.variableList,
                 input: [
                  StreamToken.variable("var1"),
                  StreamToken.colon,
                  StreamToken.name("String"),
                  StreamToken.comma,
                  StreamToken.variable("var2"),
                  StreamToken.colon,
                  StreamToken.name("Int"),
                  StreamToken.assignment,
                  StreamToken.intValue(0)],
                 val: [
                  VariableDefinition(name: "var1",
                                     type: Type.named("String"),
                                     defaultValue: nil,
                                     directives: []),
                  VariableDefinition(name: "var2",
                                     type: Type.named("Int"),
                                     defaultValue: Value.int(0),
                                     directives: [])])
  }
  func testAlias() {
    assertParsed(GraphQlDocumentParser.alias,
                 input: [
                  StreamToken.name("otherName"),
                  StreamToken.colon],
                 val: "otherName")
  }
  func testFragmentSpread() {
    assertParsed(GraphQlDocumentParser.fragmentSpread,
                 input: [
                  StreamToken.ellipsis,
                  StreamToken.name("FragmentName")],
                 val: Selection.fragmentSpread("FragmentName", []))
  }
  func testInlineFragment() {
    let inlineFragment = GraphQlDocumentParser.inlineFragment()
    // ... on SomeType { aField }
    assertParsed(inlineFragment,
                 input: [
                  StreamToken.ellipsis,
                  StreamToken.on,
                  StreamToken.name("SomeType"),
                  StreamToken.leftCurly,
                  StreamToken.name("aField"),
                  StreamToken.rightCurly],
                 val: Selection.inlineFragment(Type.named("SomeType"), [], [Selection.field(Field(named: "aField"))]))
    
    // ... { aField }
    assertParsed(inlineFragment,
                 input: [
                  StreamToken.ellipsis,
                  StreamToken.leftCurly,
                  StreamToken.name("aField"),
                  StreamToken.rightCurly],
                 val: Selection.inlineFragment(nil, [], [Selection.field(Field(named: "aField"))]))
  }
  func testField() {
    // test
    let field = GraphQlDocumentParser.field()
    
    assertParsed(field,
                 input: [StreamToken.name("test")],
                 val: Field(named: "test"))
    
    // another_name: test
    assertParsed(field,
                 input: [
                  StreamToken.name("anotherName"),
                  StreamToken.colon,
                  StreamToken.name("test")],
                 val: Field(
                  named: "test",
                  alias: "anotherName"))
    
    // test @directive(name: "value")
    assertParsed(field,
                 input: [
                  StreamToken.name("test"),
                  StreamToken.directive("directive"),
                  StreamToken.leftParen, StreamToken.name("name"),
                  StreamToken.colon,
                  StreamToken.stringValue("value"),
                  StreamToken.rightParen],
                 val: Field(
                  named: "test",
                  directives: [
                    Directive(
                      name: "directive",
                      arguments: [
                        Argument(
                          name: "name",
                          value: Value.string("value"))])],
                  selectionSet: []))
    
    // field { subfield }
    assertParsed(field,
                 input: [
                  StreamToken.name("field"),
                  StreamToken.leftCurly,
                  StreamToken.name("subfield"),
                  StreamToken.rightCurly],
                 val: Field(named: "field", selectionSet: [Selection.field(Field(named: "subfield"))]))
    
    // field(name: 0)
    assertParsed(field,
    input: [
     StreamToken.name("field"),
     StreamToken.leftParen,
     StreamToken.name("name"),
     StreamToken.colon,
     StreamToken.intValue(0),
     StreamToken.rightParen],
    val: Field(named: "field", arguments: [Argument(name: "name", value: Value.int(0))]))
  }
  
  func testSelectionSet() {
    let result = GraphQlLexer.lexer(AnyCollection("""
    {
      aField(name: "value")
      ...Fragment
      ... on SomeType { anotherField }
    }
    """))
    
    
    let tokens: [StreamToken] = [
      .leftCurly,
      .name("aField"),
      .leftParen,
      .name("name"),
      .colon,
      .stringValue("value"),
      .rightParen,
      .ellipsis,
      .name("Fragment"),
      .ellipsis,
      .on,
      .name("SomeType"),
      .leftCurly,
      .name("anotherField"),
      .rightCurly,
      .rightCurly
    ]
    
    XCTAssertEqual(tokens, try! result.get().0.filter({ $0 != StreamToken.whitespace }))
    
    
    let selectionSet = GraphQlDocumentParser.selectionSet()
    assertParsed(selectionSet,
                 input: tokens,
                 val: [
                  Selection.field(
                    Field(
                      named: "aField",
                      arguments: [
                        Argument(
                          name: "name",
                          value: Value.string("value"))])),
                  Selection.fragmentSpread("Fragment", []),
                  Selection.inlineFragment(
                    Type.named("SomeType"), [], [
                      Selection.field(
                        Field(named: "anotherField"))])])
    
  }
  
  func testSimpleOpDefinition() {
    let tokens = [
      StreamToken.leftCurly,
      .name("aField"),
      .rightCurly
    ]
    assertParsed(GraphQlDocumentParser.simpleOperationDefinition,
                 input: tokens,
                 val: OperationDefinition([
                  Selection.field(Field(named: "aField"))]))
  }
  func testFullOperationDefinition() {
    let result = GraphQlLexer.lexer(AnyCollection("""
    query GetFoo($var: String) {
      field(var: $var) {
        aField
      }
    }
    """))
    
    let tokens: [StreamToken] = [
      .query,
      .name("GetFoo"),
      .leftParen,
      .variable("var"),
      .colon,
      .name("String"),
      .rightParen,
      .leftCurly,
      .name("field"),
      .leftParen,
      .name("var"),
      .colon,
      .variable("var"),
      .rightParen,
      .leftCurly,
      .name("aField"),
      .rightCurly,
      .rightCurly
    ]
        
    XCTAssertEqual(tokens, try! result.get().0.filter({ $0 != StreamToken.whitespace }))
    
    assertParsed(GraphQlDocumentParser.fullOperationDefinition,
                 input: tokens,
                 val: OperationDefinition([Selection.field(Field(
                  named: "field",
                  arguments: [
                    Argument(
                      name: "var",
                      value: Value.variable("var"))],
                  selectionSet: [Selection.field(Field(named: "aField"))]))],
                  operationType: OperationType.query,
                  name: "GetFoo",
                  variableDefinitions: [
                    VariableDefinition(name: "var", type: Type.named("String"), defaultValue: nil, directives: [])],
                  directives: []))
    
  }
  func testFragmentDefinition() {
    assertParsed(GraphQlDocumentParser.fragmentDefinition,
                 input: [
                  StreamToken.fragment,
                  .name("Foo"),
                  .on,
                  .name("SomeType"),
                  .leftCurly,
                  .name("query_field"),
                  .rightCurly],
                 val: ExecutableDefinition.fragment(FragmentDefinition(
                  name: "Foo",
                  typeCondition: Type.named("SomeType"),
                  directives: [],
                  selectionSet: [
                    Selection.field(
                      Field(named: "query_field"))])))
  }
  func testExecutableDefinition() {
    let result = GraphQlLexer.lexer(AnyCollection("""
    query GetPost($postId: ID!) {
      post(id: $postId) {
        title
        created_at
      }
    }
    """))


    let tokens: [StreamToken] = [
      .query,
      .name("GetPost"),
      .leftParen,
      .variable("postId"),
      .colon,
      .name("ID"),
      .exclamation,
      .rightParen,
      .leftCurly,
      .name("post"),
      .leftParen,
      .name("id"),
      .colon,
      .variable("postId"),
      .rightParen,
      .leftCurly,
      .name("title"),
      .name("created_at"),
      .rightCurly,
      .rightCurly
    ]
        
    let expectedTokens = try! result.get().0.filter({ $0 != StreamToken.whitespace })
    XCTAssertEqual(tokens, expectedTokens)
    
    assertParsed(GraphQlDocumentParser.executableDefinition,
                input: expectedTokens,
                val: Definition.executable( ExecutableDefinition.operation(OperationDefinition([Selection.field(Field(
                 named: "post",
                 arguments: [
                   Argument(
                     name: "id",
                     value: Value.variable("postId"))],
                 selectionSet: [
                  Selection.field(Field(named: "title")),
                  Selection.field(Field(named: "created_at"))]))],
                 operationType: OperationType.query,
                 name: "GetPost",
                 variableDefinitions: [
                  VariableDefinition(name: "postId", type: Type.required(Type.named("ID")), defaultValue: nil, directives: [])],
                 directives: []))))
    
  }
  
  func testScalarTypeDefinition() {
    let result = GraphQlLexer.lexer(AnyCollection("""
      "A Foo scalar"
      scalar Foo
    """))
    
    let tokens: [StreamToken] = [
      .stringValue("A Foo scalar"),
      .scalar,
      .name("Foo")
    ]
        
    let expectedTokens = try! result.get().0.filter({ $0 != StreamToken.whitespace })
    XCTAssertEqual(tokens, expectedTokens)
    
    assertParsed(
      GraphQlDocumentParser.scalarTypeDefinition,
      input: tokens,
      val: TypeDefinition.scalar(ScalarTypeDefinition(description: "A Foo scalar", name: "Foo", directives: [])))
  }
  
  func testObjectTypeDefinition() {
    let result = GraphQlLexer.lexer(AnyCollection("""
      "Foo object description"
      type Foo implements ThingOne & ThingTwo {
        field1: String
      }
    """))
    
    let tokens: [StreamToken] = [
      .stringValue("Foo object description"),
      .typ,
      .name("Foo"),
      .implements,
      .name("ThingOne"),
      .ampersand,
      .name("ThingTwo"),
      .leftCurly,
      .name("field1"),
      .colon,
      .name("String"),
      .rightCurly
    ]
    
    let expectedTokens = try! result.get().0.filter({ $0 != StreamToken.whitespace })
    XCTAssertEqual(tokens, expectedTokens)
    
    assertParsed(
      GraphQlDocumentParser.objectTypeDefinition,
      input: tokens,
      val: TypeDefinition.object(
        ObjectTypeDefinition(
          description: "Foo object description",
          name: "Foo",
          interfaces: [Type.named("ThingOne"), Type.named("ThingTwo")],
          fields: [
            FieldDefinition(
              description: nil,
              name: "field1",
              arguments: [],
              type: Type.named("String"),
              directives: [])
          ],
          directives: [])))
  }
  
  static var allTests = [
      ("testName", testName),
  ]
}


