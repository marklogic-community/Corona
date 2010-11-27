import module namespace jsonpath="http://marklogic.com/json-path" at "../lib/json-path.xqy";

let $json := "{ key: ""book"", comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], andPredicate: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""book"", value: {key:""id"", value:""0596000405""}, comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], andPredicate: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""book"", value: {key:""id""}, comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], andPredicate: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""id"", value: [""0596000405"", ""123456789""], comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], andPredicate: [], innerKey: {}, position: ""1 to last()"" }"

let $json := "{ key: ""book"", value:{innerKey:""id"", value: [""0596000405"", ""123456789""]}, comparison: ""="", orPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], andPredicate: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], position: ""1 to last()"" }"

return jsonpath:parse($json)
