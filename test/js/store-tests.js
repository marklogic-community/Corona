if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}


corona.documents = [
    {
        "type": "binary",
        "uri": "/doc-store-test-1.jpg",
        "content": "Mary had a little binary document.",
        "contentForBinary": '{"tagline": "Mary had a little binary document."}',
        "outputFormat": "json"
    },
    {
        "type": "text",
        "uri": "/doc-store-test-1.text",
        "content": "Mary had a little text document.",
        "outputFormat": "json"
    },
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
        "uri": "/doc-with-date.xml",
        "content": "<foo>bar</foo>",
        "applyTransform": "adddate"
    },
    {
        "type": "xml",
        "uri": "/doc-store-test-6.xml",
        "permissions": {
            "nonexistant": ["read"]
        },
        "content": "<foo>bar</foo>",
        "shouldSucceed": false
    },
    {
        "type": "xml",
        "uri": "",
        "content": "<foo>bar</foo>",
        "shouldSucceed": false
    }
];

corona.constructURL = function(verb, doc, prefix, processExtras, includeOutputFormat, staticExtras) {
    var extras = [];
    if(staticExtras) {
        extras.push(staticExtras);
    }

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
                        extras.push(permissionArg + "=" + role + ":" + roles[j]);
                    }
                }
            }
        }
        if(doc.properties !== undefined) {
            for(var property in doc.properties) {
                if(!(doc.properties[property] instanceof Function)) {
                    var value = doc.properties[property];
                    if(propertyArg === "removeProperty") {
                        extras.push(propertyArg + "=" + property);
                    }
                    else {
                        extras.push(propertyArg + "=" + property + ":" + value);
                    }
                }
            }
        }
        if(doc.collections !== undefined) {
            var j = 0;
            for(j = 0; j < doc.collections.length; j += 1) {
                extras.push(collectionArg + "=" + doc.collections[j]);
            }
        }
        if(doc.quality !== undefined) {
            extras.push("quality=" + doc.quality);
        }
    }

    if(includeOutputFormat && doc.outputFormat) {
        extras.push("outputFormat=" + doc.outputFormat);
    }

    if((verb === "PUT" || verb === "POST") && doc.contentForBinary) {
        extras.push("contentForBinary=" + doc.contentForBinary);
    }

    if((verb === "PUT" || verb === "POST") && doc.applyTransform) {
        extras.push("applyTransform=" + doc.applyTransform);
        extras.push("respondWithContent=true");
    }

    extras.push("uri=" + encodeURIComponent(prefix + doc.uri));
    return "/store?" + extras.join("&");
};

corona.compareJSONDocuments = function(model, actual, withExtras) {
    delete actual.permissions["corona-dev"];
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

corona.compareTextDocuments = function(model, actual, withExtras) {
    equal(model.content, actual.content, "Contet matches");
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


corona.insertDocuments = function(prefix, withExtras, callback) {
    var i = 0;
    for(i = 0; i < corona.documents.length; i += 1) {
        if((corona.documents[i].type === "json" && corona.stash.status.features.JSONDocs === false) || corona.documents[i].shouldSucceed === false) {
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
                    url: corona.constructURL("PUT", doc, prefix, processExtras, false),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        $.ajax({
                            url: corona.constructURL("GET", doc, prefix, "ignore", true, doc.type === "binary" ? undefined : "include=all"),
                            type: 'GET',
                            context: this,
                            success: function(data) {
                                if(this.type === "json") {
                                    corona.compareJSONDocuments(this, data, withExtras);
                                }
                                else if(this.type === "text") {
                                    corona.compareTextDocuments(this, data, withExtras);
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

corona.insertAndMoveDocuments = function(prefix) {
    var i = 0;
    for(i = 0; i < corona.documents.length; i += 1) {
        if((corona.documents[i].type === "json" && corona.stash.status.features.JSONDocs === false) || corona.documents[i].shouldSucceed === false) {
            continue;
        }

        var wrapper = function(index) {
            var doc = corona.documents[index];
            asyncTest("Inserting document: " + prefix + doc.uri, function() {
                var docContent = doc.content;
                if(doc.type === "json") {
                    docContent = JSON.stringify(docContent);
                }
                processExtras = "set";
                $.ajax({
                    url: corona.constructURL("PUT", doc, prefix, processExtras, false),
                    type: 'PUT',
                    data: docContent,
                    context: doc,
                    success: function() {
                        ok(true, "Inserted document");
                        $.ajax({
                            url: "/store",
                            data: {
                                "uri": prefix + doc.uri,
                                "moveTo": "/moved" + doc.uri
                            },
                            type: 'POST',
                            context: this,
                            success: function(data) {
                                $.ajax({
                                    url: corona.constructURL("GET", doc, "/moved", "ignore", true, doc.type === "binary" ? undefined : "include=all"),
                                    type: 'GET',
                                    context: this,
                                    success: function(data) {
                                        if(this.type === "json") {
                                            corona.compareJSONDocuments(this, data, true);
                                        }
                                        else if(this.type === "text") {
                                            corona.compareTextDocuments(this, data, true);
                                        }
                                        else {
                                            corona.compareXMLDocuments(this, data, true);
                                        }

                                        corona.deleteDocument("/moved", this);
                                    },
                                    error: function(j, t, error) {
                                        ok(false, "Could not fetch moved document");
                                    },
                                    complete: function() {
                                        start();
                                    }
                                });
                            },
                            error: function(j, t, error) {
                                corona.deleteDocument("/moved", this);
                                corona.deleteDocument(prefix, this);
                                ok(false, "Could not move document");
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
        if((corona.documents[i].type === "json" && corona.stash.status.features.JSONDocs === false) || corona.documents[i].shouldSucceed === undefined || corona.documents[i].shouldSucceed === true) {
            continue;
        }

        var wrapper = function(index) {
            var doc = corona.documents[index];
            var uri = "";
            if(doc.uri.length > 0) {
                uri = prefix;
            }
            asyncTest("Inserting document: " + uri, function() {
                var docContent = doc.content;
                if(doc.type === "json") {
                    docContent = JSON.stringify(docContent);
                }
                $.ajax({
                    url: corona.constructURL("PUT", doc, uri, true, false),
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
            url: corona.constructURL("POST", doc, prefix, "set", false),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL("GET", doc, prefix, "ignore", true, doc.type === "binary" ? undefined : "include=all"),
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, data, true);
                        }
                        else if(this.type === "text") {
                            corona.compareTextDocuments(this, data, true);
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
            url: corona.constructURL("POST", doc, prefix, "remove", false),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL("GET", doc, prefix, "ignore", true, doc.type === "binary" ? undefined : "include=all"),
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, data, false);
                        }
                        else if(this.type === "text") {
                            corona.compareTextDocuments(this, data, false);
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
            url: corona.constructURL("POST", doc, prefix, "add", false),
            type: 'POST',
            context: doc,
            success: function() {
                ok(true, "Updated document extras");
                $.ajax({
                    url:  corona.constructURL("GET", doc, prefix, "ignore", true, doc.type === "binary" ? undefined : "include=all"),
                    type: 'GET',
                    context: this,
                    success: function(data) {
                        if(this.type === "json") {
                            corona.compareJSONDocuments(this, data, true);
                        }
                        else if(this.type === "text") {
                            corona.compareTextDocuments(this, data, true);
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
            url: corona.constructURL("DELETE", doc, prefix, "ignore", true),
            type: 'DELETE',
            context: doc,
            success: function() {
                ok(true, "Deleted document");
                $.ajax({
                    url:  corona.constructURL("GET", doc, prefix, "ignore", true, doc.type === "binary" ? undefined : "include=all"),
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
    corona.fetchInfo(function(info) {
        corona.stash.status = info;
        corona.insertDocuments("/no-extras", false);
        corona.insertDocuments("/extras", true);
        corona.insertAndMoveDocuments("/moveme");
        corona.runFailingTests("/failures");
    });
});
