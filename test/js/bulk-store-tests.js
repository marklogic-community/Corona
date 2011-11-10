if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.documents = [
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

corona.constructURL = function(doc, prefix, processExtras) {
    return "/store?uri=" + encodeURIComponent(prefix + doc.uri) + "&contentType=" + doc.type;
};

corona.insertDocuments = function(prefix, callback) {
    var i = 0;
    for(i = 0; i < corona.documents.length; i += 1) {
        if(corona.documents[i].type === "json" && corona.stash.status.features.JSONDocs === false) {
            continue;
        }

        var wrapper = function(index) {
            var doc = corona.documents[index];
            asyncTest("Inserting document: " + prefix + doc.uri, function() {
                var docContent = doc.content;
                if(doc.type === "json") {
                    docContent = JSON.stringify(docContent);
                }

                $.ajax({
                    url: corona.constructURL(doc, prefix),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        if(index === corona.documents.length - 1) {
                            corona.deleteDocuments();
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

corona.deleteDocuments = function() {
    asyncTest("Bulk delete check", function() {
        $.ajax({
            url: '/store?structuredQuery={"keyExists": "foo"}',
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
            url: '/store?structuredQuery={"keyExists": "bar"}',
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
            url: '/store?structuredQuery={"keyExists": "foo"}&bulkDelete=true',
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
            url: '/store?structuredQuery={"element": "foo", "equals": "bar"}&bulkDelete=true&limit=2',
            type: 'DELETE',
            success: function() {
                ok(true, "Deleted documents (with limit)");

                asyncTest("Deleting XML documents", function() {
                    $.ajax({
                        url: '/store?structuredQuery={"element": "foo", "equals": "bar"}&bulkDelete=true',
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

corona.deleteDocument = function(prefix, doc) {
    asyncTest("Deleting document: " + prefix + doc.uri, function() {
        $.ajax({
            url: corona.constructURL(doc, prefix, "remove"),
            type: 'DELETE',
            context: doc,
            success: function() {
                ok(true, "Deleted document");
                $.ajax({
                    url:  corona.constructURL(doc, prefix, "ignore") + "include=all",
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
    corona.fetchInfo(function(info) {
        corona.stash.status = info;
        corona.insertDocuments("/bulk", function() {
        });
    });
});
