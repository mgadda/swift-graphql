# SwiftGraphQl

Use SwiftGraphQl to parse GraphQL documents (queries and type definitions). SwiftGraphQl defines a complete abstract syntax tree for programmatically working with GraphQL documents. It aims to be (though is not quite yet) fully compliant with the [latest working draft of the GraphQL spec](https://graphql.github.io/graphql-spec/draft/).

SwiftGraphQl has only one dependency which is [SwiftParse](https://github.com/mgadda/swift-parse), a purely swift-based parser combinator library.

## Example

```graphql
let source = """
query GetPost($postId: ID!) {
  post(id: $postId) {
    title
    created_at
  }
}
"""
let document = try! parseGraphQl(source: source)
print(document)
```

The code snippet above produces the following AST:

```graphql
[
    SwiftGraphQl.ExecutableDefinition.opDefinition (
        SwiftGraphQl.OperationDefinition (
            selectionSet : [
                SwiftGraphQl.Selection.field (
                    SwiftGraphQl.Field (
                        alias : nil,
                        name : "post",
                        arguments : [
                            SwiftGraphQl.Argument (
                                name : "id",
                                value : SwiftGraphQl.Value.variable ("postId")
                            )
                        ],
                        directives : [],
                        selectionSet : [
                            SwiftGraphQl.Selection.field (
                                SwiftGraphQl.Field (
                                    alias : nil,
                                    name : "title",
                                    arguments : [],
                                    directives : [],
                                    selectionSet : []
                                )
                            ),
                            SwiftGraphQl.Selection.field (
                                SwiftGraphQl.Field (
                                    alias : nil,
                                    name : "created_at",
                                    arguments : [],
                                    directives : [],
                                    selectionSet : []
                                )
                            )
                        ]
                    )
                )
            ],
            operationType : SwiftGraphQl.OperationType.query,
            name : Optional ("GetPost"),
            variableDefinitions : [
                SwiftGraphQl.VariableDefinition (
                    name : "postId",
                    type : SwiftGraphQl.Type.required (SwiftGraphQl.Type.named("ID")),
                    defaultValue : nil,
                    directives : []
                )
            ],
            directives : []
        )
    )
]
```
Not exactly for human consumption but great for your programmatic needs.

## Command line interface

SwiftGraphQl also comes with a command line interface: `graphql-cli`.

```
graphql-cli --help
usage: graphql-cli parse [filename]
Use `-` in place of `[filename]` to read from stdin.
```

If the document can be parsed successfully, the program exits with success status (0). If it cannot be parsed, a terse error message is emitted to standard error and the program exists with status code of 1.

Pass `-` in place of `[filename]` if the document to be parsed is available for reading on `stdin` instead of from a file:

```
echo "query TotallyValidQuery { foo }" | graphql-cli parse -
```
