if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.queries = [
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/stringquery/doc1.json",
            "content": {"subject": "bar00001"}
        },
        "query": {
            "stringQuery": "bar00001",
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/stringquery/doc1.json", "Correct document URI was found");
            equals(data.results[0].content.subject, "bar00001", "Correct document content was found");
        },
        "purpose": "Simple keyword search"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/stringquery/doc3.json",
            "content": {"subject": "bar00002"},
            "collection": ["testcol"]
        },
        "query": {
            "stringQuery": "bar00002",
            "include": ["collections"],
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data, config) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/stringquery/doc3.json", "Correct document URI was found");
            deepEqual(data.results[0].collections, config.prereqDoc.collection, "Correct document URI was found");
        },
        "purpose": "Extracting collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/stringquery/doc2.json",
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
            "stringQuery": "bar00003",
            "extractPath": "foo2.bar[0]",
            "outputFormat": "json"
         },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/stringquery/doc2.json", "Correct document URI was found");
            equals(data.results[0].content, "baz", "Correct document content was found");
        },
        "purpose": "Using extractPath"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/stringquery/doc1.xml",
            "content": "<testns:subject xmlns:testns='http://test.ns/uri'>bar00004</testns:subject>"
        },
        "query": {
            "stringQuery": "bar00004",
            "applyTransform": "generic",
            "outputFormat": "xml"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/stringquery/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XSLT'd!", "Correct document content was found");
        },
        "purpose": "Applying XSLT transform"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/stringquery/doc1.xml",
            "content": "<testns:subject xmlns:testns='http://test.ns/uri'>bar00004</testns:subject>"
        },
        "query": {
            "stringQuery": "bar00004",
            "applyTransform": "xqtrans",
            "outputFormat": "xml"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/stringquery/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XQuery'd!", "Correct document content was found");
        },
        "purpose": "Applying XQuery transform"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/stringquery/doc8.json",
            "content": {}
        },
        "query": {},
        "shouldSucceed": false,
        "purpose": "Mising query"
    },
];

corona.constructURL = function(query, purpose) {
    if(purpose === "prereq" || purpose === "delete") {
        var base = "/store";
        var extras = []
        extras.push("uri=" + encodeURIComponent(query.prereqDoc.uri));
        if(purpose === "prereq") {
            if(query.prereqDoc.collection !== undefined) {
                extras.push("collection=" + query.prereqDoc.collection);
            }
            if(query.prereqDoc.property !== undefined) {
                extras.push("property=" + query.prereqDoc.property);
            }
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
    module("String Query Endpoint");
    corona.runQueries();
});
