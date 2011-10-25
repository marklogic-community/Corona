if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.queries = [
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/querystring/doc1.json",
            "content": {"subject": "bar00001"}
        },
        "query": {
            "q": "bar00001"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/querystring/doc1.json", "Correct document URI was found");
            equals(data.results[0].content.subject, "bar00001", "Correct document content was found");
        },
        "purpose": "Simple keyword search"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/querystring/doc3.json",
            "content": {"subject": "bar00002"},
            "collection": ["testcol"]
        },
        "query": {
            "q": "bar00002",
            "include": ["collections"]
         },
        "shouldSucceed": true,
        "assert": function(data, config) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/querystring/doc3.json", "Correct document URI was found");
            deepEqual(data.results[0].collections, config.prereqDoc.collection, "Correct document URI was found");
        },
        "purpose": "Extracting collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/querystring/doc2.json",
            "content": {
                "subject": "bar00003",
                "foo2": {
                    "bar": [
                        "baz"
                    ]
                }
            }
        },
        "query": {
            "q": "bar00003",
            "extractPath": "foo2.bar[0]"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/querystring/doc2.json", "Correct document URI was found");
            equals(data.results[0].content, "baz", "Correct document content was found");
        },
        "purpose": "Using extractPath"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/querystring/doc1.xml",
            "content": "<testns:subject xmlns:testns='http://test.ns/uri'>bar00004</testns:subject>"
        },
        "query": {
            "q": "bar00004",
            "applyTransform": "generic",
            "extractPath": ""
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/querystring/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XSLT'd!", "Correct document content was found");
        },
        "purpose": "Applying transform"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/querystring/doc8.json",
            "content": {}
        },
        "query": {},
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
            base = "/json/query";
        }
        else {
            base = "/xml/query";
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
    module("Key/Value Queries");
    corona.runQueries();
});
