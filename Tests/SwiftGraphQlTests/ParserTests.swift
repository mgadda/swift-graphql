import XCTest
@testable import SwiftGraphQl
import SwiftParse

final class ParserTests: XCTestCase {
    func testParser() {
      let doc = GraphQlParser(source: "query { test }")
      XCTAssertNil(doc)
      XCTAssertEqual(doc, [ExecutableDefinition.opDefinition(OperationDefinition([Selection.field(Field(alias: nil, name: "test", arguments: [], directives: [], selectionSet: []))]))])
    }

    static var allTests = [
        ("testParser", testParser),
    ]
}
