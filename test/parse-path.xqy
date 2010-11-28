import module namespace jsonpath="http://marklogic.com/json-path" at "../lib/json-path.xqy";

let $json := "{ key: ""book"", comparison: ""="", or: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], and: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""book"", value: {key:""id"", value:""0596000405""}, comparison: ""="", or: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], and: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""book"", value: {key:""id""}, comparison: ""="", or: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], and: [], innerKey: {}, position: ""1 to last()"" }"
let $json := "{ key: ""id"", value: [""0596000405"", ""123456789""], comparison: ""="", or: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], and: [], innerKey: {}, position: ""1 to last()"" }"

let $json := "{ key: ""book"", value:{innerKey:""id"", value: [""0596000405"", ""123456789""]}, comparison: ""="", or: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], and: [{key: ""id"", value: ""0596000405""}, {key: ""other_id"", value: ""0596000405""}], position: ""1 to last()"" }"

let $json := "{ fulltext: {
        or: [
            { equals: {
                key: ""greeting"",
                string: ""Hello World"",
                weight: 2.0,
                caseSensitive: false,
                diacriticSensitive: true,
                punctuationSensitve: false,
                whitespaceSensitive: false,
                stemmed: true,
                wildcarded: true,
                minimumOccurances: 1,
                maximumOccurances: null
            }},
            { contains: {
                key: ""para"",
                string: ""Hello World"",
                weight: 1.0
            }},
            { rangeignore: {
                key: ""para"",
                value: ""Hello World"",
                weight: 1.0,
                operator: ""=""
            }},
            { geo: {
                parent: ""location"",
                latKey: ""latitude"",
                longKey: ""longitude"",
                key: ""latlong"",
                region: [
                    {point: {longitude: 12, latitude: 53}},
                    {circle: {longitude: 12, latitude: 53, radius: 10}},
                    {box: {north: 3, east: 4, south: -5, west: -6}},
                    {polygon:[
                        {longitude:12, latitude:53},
                        {longitude:15, latitude:57},
                        {longitude:12, latitude:53}
                    ]}
                ]
            }},
            { collection: ""foo"" }
        ],
        filtered: false(),
        score: ""logtfidf""
    },
    position: ""1 to 10""
}"

return jsonpath:parse($json)
