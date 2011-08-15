if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.documents = [
    {
        "type": "json",
        "uri": "/doc-store-test-1.json",
        "content": { "foo": "bar" }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-2.json",
        "content": { "foo": "bar" }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-3.json",
        "content": { "foo": "bar" }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-4.json",
        "content": { "foo": "bar" }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-5.json",
        "content": { "foo": "bar" }
    },

    {
        "type": "xml",
        "uri": "/doc-store-test-1.xml",
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-2.xml",
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-3.xml",
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-4.xml",
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-5.xml",
        "content": "<foo>bar</foo>"
    }
];

mljson.constructURL = function(doc, prefix, processExtras) {
    var extras = "";
    if(doc.type === "json") {
        return "/json/store" + prefix + doc.uri + "?" + extras;
    }
    else {
        return "/xml/store" + prefix + doc.uri + "?" + extras;
    }
};

mljson.insertDocuments = function(prefix, callback) {
    var i = 0;
    for(i = 0; i < mljson.documents.length; i += 1) {
        var wrapper = function(index) {
            var doc = mljson.documents[index];
            asyncTest("Inserting document: " + prefix + doc.uri, function() {
                var docContent = doc.content;
                if(doc.type === "json") {
                    docContent = JSON.stringify(docContent);
                }

                $.ajax({
                    url: mljson.constructURL(doc, prefix),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        if(index === mljson.documents.length - 1) {
                            mljson.deleteDocuments();
                        }
                    },
                    error: function(j, t, error) {
                        ok(false, "Could not insert document");
                    },
                    complete: function() {
                        start();
                    }
                });
            });
        }.call(this, i);
    }
};

mljson.deleteDocuments = function() {
    asyncTest("Bulk delete check", function() {
        $.ajax({
            url: '/json/store?customquery={"keyExists": "foo"}',
            type: 'DELETE',
            success: function() {
                ok(false, "Deleted documents");
            },
            error: function(j, t, error) {
                ok(true, "Could not delete documents");
            },
            complete: function() {
                start();
            }
        });
    });
    asyncTest("No documents check", function() {
        $.ajax({
            url: '/json/store?customquery={"keyExists": "bar"}',
            type: 'DELETE',
            success: function() {
                ok(false, "Deleted documents");
            },
            error: function(j, t, error) {
                ok(true, "No documents to to deelete");
            },
            complete: function() {
                start();
            }
        });
    });

    asyncTest("Deleting JSON documents", function() {
        $.ajax({
            url: '/json/store?customquery={"keyExists": "foo"}&bulkDelete=true',
            type: 'DELETE',
            success: function() {
                ok(true, "Deleted documents");
            },
            error: function(j, t, error) {
                ok(false, "Could not delete documents: " + error);
            },
            complete: function() {
                start();
            }
        });
    });

    asyncTest("Deleting XML documents", function() {
        $.ajax({
            url: '/xml/store?customquery={"equals": {"element": "foo", "value": "bar"}}&bulkDelete=true',
            type: 'DELETE',
            success: function() {
                ok(true, "Deleted documents");
            },
            error: function(j, t, error) {
                ok(false, "Could not delete documents: " + error);
            },
            complete: function() {
                start();
            }
        });
    });
};

mljson.deleteDocument = function(prefix, doc) {
    asyncTest("Deleting document: " + prefix + doc.uri, function() {
        $.ajax({
            url: mljson.constructURL(doc, prefix, "remove"),
            type: 'DELETE',
            context: doc,
            success: function() {
                ok(true, "Deleted document");
                $.ajax({
                    url:  mljson.constructURL(doc, prefix, "ignore") + "include=all",
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        ok(false, "Document not truly deleted");
                    },
                    error: function(j, t, error) {
                        ok(true, "Document truly deleted");
                    },
                    complete: function() {
                        start();
                    }
                });
            },
            error: function(j, t, error) {
                ok(false, "Could not delete document");
            }
        });
    });
};

$(document).ready(function() {
    module("Bulk Store");
    mljson.insertDocuments("/bulk", function() {
    });
});
