if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.queries = [
    {
        "type": "text",
        "prereqDoc": {
            "uri": "/structquery/doc1.text",
            "content": "bar 123.45-5"
        },
        "query": {
            "structuredQuery": JSON.stringify({
                "inTextDocument": "bar 123.45-5"
            }),
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/structquery/doc1.text", "Correct document URI was found");
            equals(data.results[0].content, "bar 123.45-5", "Correct document content was found");
        },
        "purpose": "Simple text structured query"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/structquery/doc1.json",
            "content": {
                "foo": "bar 123.45-6"
            }
        },
        "query": {
            "structuredQuery": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-6"
            }),
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/structquery/doc1.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-6", "Correct document content was found");
        },
        "purpose": "Simple JSON structured query"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/structquery/doc3.json",
            "content": {"foo": "bar 123.45-7"},
            "collection": ["testcol"]
        },
        "query": {
            "structuredQuery": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-7"
            }),
            "include": ["collections"],
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data, config) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/structquery/doc3.json", "Correct document URI was found");
            deepEqual(data.results[0].collections, config.prereqDoc.collection, "Correct document collections were found");
        },
        "purpose": "Extracting collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/structquery/doc2.json",
            "content": {
                "foo": "bar 123.45-9",
                "foo2": {
                    "bar": [
                        "baz"
                    ]
                }
            }
        },
        "query": {
            "structuredQuery": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-9"
            }),
            "extractPath": "foo2.bar[0]",
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/structquery/doc2.json", "Correct document URI was found");
            equals(data.results[0].content, "baz", "Correct document content was found");
        },
        "purpose": "Using extractPath"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/structquery/doc1.xml",
            "content": "<foo>bar 123.45-1</foo>"
        },
        "query": {
            "structuredQuery": JSON.stringify({
                "element": "foo",
                "equals": "bar 123.45-1"
            }),
            "applyTransform": "generic",
            "outputFormat": "xml"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/structquery/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XSLT'd!", "Correct document content was found");
        },
        "purpose": "Applying transform"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/structquery/doc8.json",
            "content": {}
        },
        "query": {
        },
        "shouldSucceed": false,
        "purpose": "Mising query"
    },
];

corona.constructURL = function(query, purpose) {
    if(purpose === "prereq" || purpose === "delete") {
        var base = "/store" + query.prereqDoc.uri;
        var extras = []
        if(purpose === "prereq") {
            if(query.prereqDoc.collection !== undefined) {
                extras.push("collection=" + query.prereqDoc.collection);
            }
            if(query.prereqDoc.property !== undefined) {
                extras.push("property=" + query.prereqDoc.property);
            }
            extras.push("contentType=" + query.type);
        }
        return base + "?" + extras.join("&");
    }
    if(purpose === "query") {
        return "/search";
    }
}

corona.runQueries = function() {
    var i = 0;
    for(i = 0; i < corona.queries.length; i += 1) {
        var wrapper = function(query) {
            asyncTest(query.purpose, function() {
                var docContent = query.prereqDoc.content;
                if(query.type === "json") {
                    docContent = JSON.stringify(docContent);
                }
                $.ajax({
                    url: corona.constructURL(query, "prereq"),
                    type: 'PUT',
                    data: docContent,
                    success: function() {
                        $.ajax({
                            url:  corona.constructURL(query, "query"),
                            type: 'GET',
                            data: query.query,
                            success: function(data) {
                                ok(query.shouldSucceed, "Query succeded");
                                if(query.assert !== undefined) {
                                    if(query.query.outputFormat === "json") {
                                        query.assert.call(this, JSON.parse(data), query);
                                    }
                                    else {
                                        query.assert.call(this, data, query);
                                    }
                                }
                                $.ajax({
                                    url: corona.constructURL(query, "delete"),
                                    type: 'DELETE',
                                    data: docContent,
                                    error: function() {
                                        ok(false, "Could not delete prereq document");
                                    }
                                });
                            },
                            error: function(j, t, error) {
                                ok(!query.shouldSucceed, "Query failed");
                                if(query.shouldSucceed === false) {
                                    $.ajax({
                                        url: corona.constructURL(query, "delete"),
                                        type: 'DELETE',
                                        data: docContent,
                                        error: function() {
                                            ok(false, "Could not delete prereq document");
                                        }
                                    });
                                }
                            },
                            complete: function() {
                                start();
                            }
                        });
                    },
                    error: function(j, t, error) {
                        ok(false, "Could not insert prereq document");
                    }
                });
            });
            
        }.call(this, corona.queries[i]);
    }
};

$(document).ready(function() {
    module("Structured Queries");
    corona.runQueries();
});
