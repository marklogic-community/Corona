if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.queries = [
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc1.json",
            "content": {
                "foo": "bar 123.45-6"
            }
        },
        "query": {
            "key": "foo",
            "value": "bar 123.45-6"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc1.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-6", "Correct document content was found");
        },
        "purpose": "Simple JSON key/value query"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc2.json",
            "content": {
                "foo::xml": "<bar>baz</bar>"
            }
        },
        "query": {
            "element": "bar",
            "value": "baz"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc2.json", "Correct document URI was found");
            equals(data.results[0].content["foo::xml"], "<bar>baz</bar>", "Correct document content was found");
        },
        "purpose": "XML element inside a JSON document"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc3.json",
            "content": {
                "foo": "bar",
                "foo2": {
                    "bar": [
                        "baz"
                    ]
                }
            }
        },
        "query": {
            "key": "foo",
            "value": "bar",
            "extractPath": "foo2.bar[0]"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc3.json", "Correct document URI was found");
            equals(data.results[0].content, "baz", "Correct document content was found");
        },
        "purpose": "Using extractPath"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc4.json",
            "content": {
                "foo": "bar 123.45-7"
            }
        },
        "query": {
            "key": "foo",
            "value": "bar 123.45-7",
            "underDirectory": "/"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc4.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-7", "Correct document content was found");
        },
        "purpose": "Using underDirectory"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc5.json",
            "content": {
                "foo": "bar 123.45-8"
            }
        },
        "query": {
            "key": "foo",
            "value": "bar 123.45-8",
            "inDirectory": "/kvq"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc5.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-8", "Correct document content was found");
        },
        "purpose": "Using inDirectory"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc6.json",
            "content": {
                "foo": "bar 123.45-9"
            },
            "collection": "col1"
        },
        "query": {
            "key": "foo",
            "value": "bar 123.45-9",
            "collection": "col1"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc6.json", "Correct document URI was found");
            equals(data.results[0].content.foo, "bar 123.45-9", "Correct document content was found");
        },
        "purpose": "Using collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc6.json",
            "content": {
                "foo": "bar 123.45-9"
            }
        },
        "query": {
            "key": "foo",
            "value": "bar 123.45-9",
            "collection": "bogus"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 0, "Got no documents");
        },
        "purpose": "Using bogus collection"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc7.json",
            "content": {},
            "property": "foo:bar"
        },
        "query": {
            "property": "foo",
            "value": "bar"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].uri, "/kvq/doc7.json", "Correct document URI was found");
        },
        "purpose": "Property query"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc8.json",
            "content": {}
        },
        "query": {
            "property": "foo"
        },
        "shouldSucceed": false,
        "purpose": "Mising value"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc8.json",
            "content": {}
        },
        "query": {
            "value": "foo"
        },
        "shouldSucceed": false,
        "purpose": "Mising key"
    },
    {
        "type": "json",
        "prereqDoc": {
            "uri": "/kvq/doc8.json",
            "content": {}
        },
        "query": {
            "start": 10,
            "end": 1
        },
        "shouldSucceed": false,
        "purpose": "Messed up start and end"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/kvq/doc1.xml",
            "content": "<foo>bar 123.45-1</foo>"
        },
        "query": {
            "element": "foo",
            "value": "bar 123.45-1",
            "applyTransform": "generic",
            "extractPath": "root()"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/kvq/doc1.xml", "Correct document URI was found");
            equals(result.getElementsByTagName("content")[0].childNodes[0].childNodes[0].nodeValue, "XSLT'd!", "Correct document content was found");
        },
        "purpose": "Applying transform"
    },
    {
        "type": "xml",
        "prereqDoc": {
            "uri": "/kvq/doc2.xml",
            "content": "<foo bar=\"baz\"/>"
        },
        "query": {
            "element": "foo",
            "attribute": "bar",
            "value": "baz"
        },
        "shouldSucceed": true,
        "assert": function(data) {
            equals(data.getElementsByTagName("results")[0].childNodes.length, 1, "Got one document");
            var result = data.getElementsByTagName("results")[0].childNodes[0];
            equals(result.getElementsByTagName("uri")[0].childNodes[0].nodeValue, "/kvq/doc2.xml", "Correct document URI was found");
        },
        "purpose": "Using XML element and attribute"
    },
];

mljson.constructURL = function(query, purpose) {
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
            base = "/json/kvquery";
        }
        else {
            base = "/xml/kvquery";
        }
        return base;
    }
}

mljson.runQueries = function() {
    var i = 0;
    for(i = 0; i < mljson.queries.length; i += 1) {
        var wrapper = function(query) {
            asyncTest(query.purpose, function() {
                var docContent = query.prereqDoc.content;
                if(query.type === "json") {
                    docContent = JSON.stringify(docContent);
                }
                $.ajax({
                    url: mljson.constructURL(query, "prereq"),
                    type: 'PUT',
                    data: docContent,
                    success: function() {
                        $.ajax({
                            url:  mljson.constructURL(query, "query"),
                            type: 'GET',
                            data: query.query,
                            success: function(data) {
                                ok(query.shouldSucceed, "Query succeded");
                                if(query.assert !== undefined) {
                                    if(query.type === "json") {
                                        query.assert.call(this, JSON.parse(data));
                                    }
                                    else {
                                        query.assert.call(this, data);
                                    }
                                }
                                $.ajax({
                                    url: mljson.constructURL(query, "delete"),
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
                                        url: mljson.constructURL(query, "delete"),
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
            
        }.call(this, mljson.queries[i]);
    }
};

$(document).ready(function() {
    module("Key/Value Queries");
    mljson.runQueries();
});
