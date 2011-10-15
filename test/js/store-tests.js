if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.documents = [
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
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-6.xml",
        "permissions": {
            "nonexistant": ["read"]
        },
        "content": "<foo>bar</foo>",
        "shouldSucceed": false
    }
];

corona.constructURL = function(doc, prefix, processExtras) {
    var extras = "";

    var permissionArg = "permission";
    var propertyArg = "property";
    var collectionArg = "collection";
    if(processExtras === "add") {
        permissionArg = "addPermission";
        propertyArg = "addProperty";
        collectionArg = "addCollection";
    }
    if(processExtras === "remove") {
        permissionArg = "removePermission";
        propertyArg = "removeProperty";
        collectionArg = "removeCollection";
    }

    if(processExtras !== "ignore") {
        if(doc.permissions !== undefined) {
            for(var role in doc.permissions) {
                if(!(doc.permissions[role] instanceof Function)) {
                    var roles = doc.permissions[role];
                    var j = 0;
                    for(j = 0; j < roles.length; j += 1) {
                        extras += permissionArg + "=" + role + ":" + roles[j] + "&";
                    }
                }
            }
        }
        if(doc.properties !== undefined) {
            for(var property in doc.properties) {
                if(!(doc.properties[property] instanceof Function)) {
                    var value = doc.properties[property];
                    if(propertyArg === "removeProperty") {
                        extras += propertyArg + "=" + property + "&";
                    }
                    else {
                        extras += propertyArg + "=" + property + ":" + value + "&";
                    }
                }
            }
        }
        if(doc.collections !== undefined) {
            var j = 0;
            for(j = 0; j < doc.collections.length; j += 1) {
                extras += collectionArg + "=" + doc.collections[j] + "&";
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

corona.compareJSONDocuments = function(model, actual, withExtras) {
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
    else {
        deepEqual(actual.permissions, {}, "No permisssions");
        deepEqual(actual.properties, {}, "No properties");
        deepEqual(actual.collections, [], "No collections");
    }

    deepEqual(model.content, actual.content, "Content matches");
};

corona.compareXMLDocuments = function(model, xmlAsString, withExtras) {
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


corona.insertDocuments = function(prefix, withExtras) {
    var i = 0;
    for(i = 0; i < corona.documents.length; i += 1) {
        if(corona.documents[i].shouldSucceed === false) {
            continue;
        }

        var wrapper = function(index) {
            var doc = corona.documents[index];
            asyncTest("Inserting document: " + prefix + doc.uri, function() {
                var docContent = doc.content;
                if(doc.type === "json") {
                    docContent = JSON.stringify(docContent);
                }
                var processExtras = "ignore";
                if(withExtras) {
                    processExtras = "set";
                }
                $.ajax({
                    url: corona.constructURL(doc, prefix, processExtras),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        $.ajax({
                            url: corona.constructURL(doc, prefix, "ignore") + "include=all",
                            type: 'GET',
                            context: this,
                            success: function(data) {
                                if(this.type === "json") {
                                    corona.compareJSONDocuments(this, JSON.parse(data), withExtras);
                                }
                                else {
                                    corona.compareXMLDocuments(this, data, true);
                                }

                                if(withExtras === false) {
                                    corona.setExtras(prefix, this);
                                }
                                else {
                                    corona.deleteDocument(prefix, this);
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

corona.runFailingTests = function(prefix) {
    var i = 0;
    for(i = 0; i < corona.documents.length; i += 1) {
        if(corona.documents[i].shouldSucceed === undefined || corona.documents[i].shouldSucceed === true) {
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
                    url: corona.constructURL(doc, prefix, true),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(false, "Test succeeded when it should have failed");
                    },
                    error: function(j, t, error) {
                        ok(true, "Test failed, as expected");
                    },
                    complete: function() {
                        start();
                    }
                });
            });
        }.call(this, i);
    }
};

corona.setExtras = function(prefix, doc) {
    asyncTest("Setting document extras: " + prefix + doc.uri, function() {
        $.ajax({
            url: corona.constructURL(doc, prefix, "set"),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL(doc, prefix, "ignore") + "include=all",
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, JSON.parse(data), true);
                        }
                        else {
                            corona.compareXMLDocuments(this, data, true);
                        }
                        corona.removeExtras(prefix, doc);
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

corona.removeExtras = function(prefix, doc) {
    asyncTest("Removing document extras: " + prefix + doc.uri, function() {
        $.ajax({
            url: corona.constructURL(doc, prefix, "remove"),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL(doc, prefix, "ignore") + "include=all",
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, JSON.parse(data), false);
                        }
                        else {
                            corona.compareXMLDocuments(this, data, false);
                        }
                        corona.addExtras(prefix, doc);
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

corona.addExtras = function(prefix, doc) {
    asyncTest("Adding document extras: " + prefix + doc.uri, function() {
        $.ajax({
            url: corona.constructURL(doc, prefix, "add"),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL(doc, prefix, "ignore") + "include=all",
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, JSON.parse(data), true);
                        }
                        else {
                            corona.compareXMLDocuments(this, data, true);
                        }
                        corona.deleteDocument(prefix, doc);
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
    module("Store");
    corona.insertDocuments("/no-extras", false);
    corona.insertDocuments("/extras", true);
    corona.runFailingTests("/failures");
});
