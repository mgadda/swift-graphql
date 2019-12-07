import SwiftParse

//"query Foo(){ foo }"
//let query: Substring = """
//{
//  user(id: 4) {
//    id
//    name
//    smallPic: profilePic(size: 64)
//    bigPic: profilePic(size: 1024)
//  }
//}
//"""

let query: Substring = """
query inlineFragmentNoType($expandedInfo: Boolean) {
  user(handle: "zuck") {
    id
    name
    ... @include(if: $expandedInfo) {
      firstName
      lastName
      birthday
    }
  }
}
"""

let lexer = GraphQlLexerFn()
guard let (result, remaining) = lexer("{ fieldName }") else {
  fatalError("Failed to parse")
}

let parser = documentParser()
if let (doc, remaining) = parser(ArraySlice(result)) {
  print("Parsed:")
  print(doc)
  print("Remaining:")
  print(remaining)
} else {
  print("Failed to parse document")
}

