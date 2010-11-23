import module namespace jsonpath="http://marklogic.com/json-path" at "../lib/json-path.xqy";

let $json := "{ key: ""id"", value: [""0596000405"", ""123456789""], comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}],  andPredicate: [],  descendant: {},  position: ""1 to last()"" }"

return jsonpath:parse($json)
