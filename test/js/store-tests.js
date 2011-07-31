if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.documents = [
    {
        "type": "json",
        "uri": "/doc-store-test-1.json",
        "content": {
            "foo": "bar"
        }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-2.json",
        "permissions": {
            "app-builder": ["read", "update"],
            "app-user": ["read"]
        },
        "content": {
            "foo": "bar"
        }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-3.json",
        "properties": {
            "state": "published",
            "active": "yes",
            "publishedOn": "January 15th, 2011"
        },
        "content": {
            "foo": "bar"
        }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-4.json",
        "collections": [
            "published",
            "active"
        ],
        "content": {
            "foo": "bar"
        }
    },
    {
        "type": "json",
        "uri": "/doc-store-test-5.json",
        "quality": 5,
        "content": {
            "foo": "bar"
        }
    },

    {
        "type": "xml",
        "uri": "/doc-store-test-1.xml",
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-2.xml",
        "permissions": {
            "app-builder": ["read", "update"],
            "app-user": ["read"]
        },
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-3.xml",
        "properties": {
            "state": "published",
            "active": "yes"
        },
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-4.xml",
        "collections": [
            "published",
            "active"
        ],
        "content": "<foo>bar</foo>"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-5.xml",
        "quality": 5,
        "content": "<foo>bar</foo>"
    }
];

mljson.constructURL = function(doc, prefix, withExtras) {
    var extras = "";
    if(withExtras) {
        if(doc.permissions !== undefined) {
            for(var role in doc.permissions) {
                if(!(doc.permissions[role] instanceof Function)) {
                    var roles = doc.permissions[role];
                    var j = 0;
                    for(j = 0; j < roles.length; j += 1) {
                        extras += "permission=" + role + ":" + roles[j] + "&";
                    }
                }
            }
        }
        if(doc.properties !== undefined) {
            for(var property in doc.properties) {
                if(!(doc.properties[property] instanceof Function)) {
                    var value = doc.properties[property];
                    extras += "property=" + property + ":" + value + "&";
                }
            }
        }
        if(doc.collections !== undefined) {
            var j = 0;
            for(j = 0; j < doc.collections.length; j += 1) {
                extras += "collection=" + doc.collections[j] + "&";
            }
        }
        if(doc.quality !== undefined) {
            extras += "quality=" + doc.quality + "&";
        }
    }

    if(doc.type === "json") {
        return "/json/store" + prefix + doc.uri + "?" + extras;
    }
    else {
        return "/xml/store" + prefix + doc.uri + "?" + extras;
    }
};

mljson.compareJSONDocuments = function(model, actual, withExtras) {
    if(withExtras) {
        if(model.permissions !== undefined) {
            for(var role in model.permissions) {
                if(!(model.permissions[role] instanceof Function)) {
                    model.permissions[role].sort();
                }
            }
            for(var role in actual.permissions) {
                if(!(actual.permissions[role] instanceof Function)) {
                    actual.permissions[role].sort();
                }
            }
            deepEqual(model.permissions, actual.permissions, "Permissions match");
        }
        if(model.properties !== undefined) {
            deepEqual(model.properties, actual.properties, "Properties match");
        }
        if(model.collections !== undefined) {
            deepEqual(model.collections.sort(), actual.collections.sort(), "Collections match");
        }
        if(model.quality !== undefined) {
            equal(model.quality, actual.quality, "Quality matches");
        }
    }

    deepEqual(model.content, actual.content, "Content matches");
};

mljson.compareXMLDocuments = function(model, xmlAsString, withExtras) {
    var parser = new DOMParser();
    var actual = parser.parseFromString(xmlAsString, "text/xml");

    if(withExtras) {
        if(model.permissions !== undefined) {
            // deepEqual(model.permissions, actual.permissions, "Permissions match");
        }
        if(model.properties !== undefined) {
            // deepEqual(model.properties, actual.properties, "Properties match");
        }
        if(model.collections !== undefined) {
            // deepEqual(model.collections.sort(), actual.collections.sort(), "Collections match");
        }
        if(model.quality !== undefined) {
            // equal(model.quality, actual.quality, "Quality matches");
        }
    }

    // deepEqual(model.content, actual.content, "Content matches");
};


mljson.insertDocuments = function(prefix, withExtras) {
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
                    url: mljson.constructURL(doc, prefix, withExtras),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        $.ajax({
                            url: mljson.constructURL(doc, prefix, false) + "include=all",
                            type: 'GET',
                            context: this,
                            success: function(data) {
                                if(this.type === "json") {
                                    mljson.compareJSONDocuments(this, JSON.parse(data), withExtras);
                                }
                                else {
                                    mljson.compareXMLDocuments(this, data, true);
                                }

                                if(withExtras === false) {
                                    mljson.addExtras(prefix, this);
                                }
                                else {
                                    mljson.deleteDocument(prefix, this);
                                }
                            },
                            error: function(j, t, error) {
                                ok(false, "Could not fetch inserted document");
                            },
                            complete: function() {
                                start();
                            }
                        });
                    },
                    error: function(j, t, error) {
                        ok(false, "Could not insert document");
                    }
                });
            });
        }.call(this, i);
    }
};

mljson.addExtras = function(prefix, doc) {
    asyncTest("Setting document extras: " + prefix + doc.uri, function() {
        $.ajax({
            url: mljson.constructURL(doc, prefix, true),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  mljson.constructURL(doc, prefix, false) + "include=all",
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            mljson.compareJSONDocuments(this, JSON.parse(data), true);
                        }
                        else {
                            mljson.compareXMLDocuments(this, data, true);
                        }
                        mljson.deleteDocument(prefix, doc);
                    },
                    error: function(j, t, error) {
                        ok(false, "Could not fetch document");
                    },
                    complete: function() {
                        start();
                    }
                });
            },
            error: function(j, t, error) {
                ok(false, "Could not update document extras");
            }
        });
    });
};

mljson.deleteDocument = function(prefix, doc) {
    asyncTest("Deleting document: " + prefix + doc.uri, function() {
        $.ajax({
            url: mljson.constructURL(doc, prefix, false),
            type: 'DELETE',
            context: doc,
            success: function() {
                ok(true, "Deleted document");
                $.ajax({
                    url:  mljson.constructURL(doc, prefix, false) + "include=all",
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
    module("Store");
    mljson.insertDocuments("/no-extras", false);
    mljson.insertDocuments("/extras", true);
});
