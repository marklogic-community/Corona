if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.queries = [
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/customquery/doc1.json",
            "content": {
                "foo": "bar 123.45-6"
            }
        },
        "query": {
            "q": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-6"
            }),
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            console.log(data);
            equals(data.results[0].uri, "/customquery/doc1.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-6", "Correct document content was found");
        },
        "purpose": "Simple JSON custom query"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/customquery/doc3.json",
            "content": {"foo": "bar 123.45-7"},
            "collection": ["testcol"]
        },
        "query": {
            "q": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-7"
            }),
            "include": ["collections"]
         },
        "shouldSucceed": true,
        "assert": function(data, config) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/customquery/doc3.json", "Correct document URI was found");
            deepEqual(data.results[0].collections, config.prereqDoc.collection, "Correct document collections were found");
        },
        "purpose": "Extracting collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/customquery/doc2.json",
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
            "q": JSON.stringify({
                "key": "foo",
                "equals": "bar 123.45-9"
            }),
            "extractPath": "foo2.bar[0]"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/customquery/doc2.json", "Correct document URI was found");
            equals(data.results[0].content, "baz", "Correct document content was found");
        },
        "purpose": "Using extractPath"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/customquery/doc1.xml",
            "content": "<foo>bar 123.45-1</foo>"
        },
        "query": {
            "q": JSON.stringify({
                "element": "foo",
                "equals": "bar 123.45-1"
            }),
            "applyTransform": "generic",
            "extractPath": ""
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/customquery/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XSLT'd!", "Correct document content was found");
        },
        "purpose": "Applying transform"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/customquery/doc8.json",
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
        var base;
        if(query.type === "json") {
            base = "/json/store";
        }
        else {
            base = "/xml/store";
        }
        base += query.prereqDoc.uri + "?";
        if(purpose === "prereq") {
            if(query.prereqDoc.collection !== undefined) {
                base += "collection=" + query.prereqDoc.collection + "&";
            }
            if(query.prereqDoc.property !== undefined) {
                base += "property=" + query.prereqDoc.property + "&";
            }
        }
        return base;
    }
    if(purpose === "query") {
        var base;
        if(query.type === "json") {
            base = "/json/customquery";
        }
        else {
            base = "/xml/customquery";
        }
        return base;
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
                                    if(query.type === "json") {
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
    module("Custom Queries");
    corona.runQueries();
});
