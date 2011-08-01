if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.removeIndexes = function(info, callback) {
    var i = 0;
    var indexes = [];
    for(i = 0; i < info.indexes.fields.length; i += 1) {
        indexes.push({"type": "field", "name": info.indexes.fields[i].name});
    }
    for(i = 0; i < info.indexes.mappings.length; i += 1) {
        indexes.push({"type": "map", "name": info.indexes.mappings[i].name});
    }
    for(i = 0; i < info.indexes.ranges.length; i += 1) {
        indexes.push({"type": "range", "name": info.indexes.ranges[i].name});
    }
    for(i = 0; i < info.indexes.bucketedRanges.length; i += 1) {
        indexes.push({"type": "bucketedrange", "name": info.indexes.bucketedRanges[i].name});
    }
    for(i = 0; i < info.xmlNamespaces.length; i += 1) {
        indexes.push({"type": "namespace", "name": info.xmlNamespaces[i].prefix});
    }
    
    var processingPosition = 0;

    var removeNextIndex = function() {
        removeIndex(processingPosition);
    };

    var removeIndex = function(pos) {
        var index = indexes[pos];
        if(index === undefined) {
            asyncTest("Check for no indexes", function() {
                $.ajax({
                    url: '/data/info',
                    success: function(data) {
                        var info = JSON.parse(data);
                        ok(info.indexes.fields.length === 0, "All fields removed");
                        ok(info.indexes.mappings.length === 0, "All mappings removed");
                        ok(info.indexes.ranges.length === 0, "All ranges removed");
                        ok(info.xmlNamespaces.length === 0, "All namespaces removed");
                        callback.call();
                    },
                    error: function() {
                        ok(false, "Could not fetch server info");
                    },
                    complete: function() { start(); }
                });
            });
            return;
        }

        asyncTest("Remove the " + index.name + " index", function() {
            var url = "/manage/" + index.type + "/" + index.name;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    processingPosition++;
                    ok(true, "Removed the " + index.name + " " + index.type);
                    removeNextIndex();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete " + index.type + ": " + error);
                },
                complete: function() {
                    start();
                }
            });
        });
    }

    removeNextIndex();
};

mljson.addIndexes = function(callback) {
    // These are the index to try and create
    var indexes = [
        {
            "type": "field",
            "pluralType": "fields",
            "name": "field1",
            "includes": [
                { "type": "key", "name": "included1"},
                { "type": "key", "name": "included2"},
                { "type": "element", "name": "nonselment"},
            ],
            "excludes": [
                { "type": "key", "name": "excluded1"},
                { "type": "element", "name": "excludenonsel"},
            ],
            "shouldSucceed": true,
            "purpose": "General field creation",
        },
        {
            "type": "map",
            "pluralType": "mappings",
            "name": "map1",
            "key": "name1",
            "mode": "contains",
            "shouldSucceed": true,
            "purpose": "General map creation"
        },
        {
            "type": "range",
            "pluralType": "ranges",
            "name": "range1",
            "key": "date1::date",
            "datatype": "date",
            "operator": "gt",
            "shouldSucceed": true,
            "purpose": "General range creation on a date"
        },
        {
            "type": "range",
            "pluralType": "ranges",
            "name": "range2",
            "key": "included1",
            "datatype": "string",
            "operator": "eq",
            "shouldSucceed": true,
            "purpose": "General range creation on a string"
        },
        {
            "type": "bucketedrange",
            "pluralType": "bucketedRanges",
            "name": "fromBucket",
            "key": "fromPersonal",
            "datatype": "string",
            "buckets": "A-F|G|G-M|N|N-R|S|S-Z",
            "shouldSucceed": true,
            "purpose": "General bucketed range creation on a string"
        },
        {
            "type": "namespace",
            "pluralType": "xmlNamespaces",
            "prefix": "testns",
            "uri": "http://test.ns/uri",
            "shouldSucceed": true,
            "purpose": "Creation of XML namespace"
        },

        {
            "type": "field",
            "pluralType": "fields",
            "name": "field1",
            "includes": [],
            "excludes": [],
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a field"
        },
        {
            "type": "map",
            "pluralType": "mappings",
            "name": "field1",
            "key": "name1",
            "mode": "equals",
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a map"
        },
        {
            "type": "range",
            "pluralType": "ranges",
            "name": "field1",
            "key": "name1",
            "datatype": "string",
            "operator": "eq",
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a range"
        },
        {
            "type": "namespace",
            "pluralType": "xmlNamespaces",
            "prefix": "test:ns",
            "uri": "http://test.ns/uri",
            "shouldSucceed": false,
            "purpose": "Should fail with invalid XML namespace prefix"
        },
        {
            "type": "range",
            "pluralType": "ranges",
            "name": "messageDate",
            "key": "date::date",
            "datatype": "date",
            "operator": "eq",
            "shouldSucceed": true,
            "purpose": "Range index for MarkMail JSON message date"
        },
        {
            "type": "range",
            "pluralType": "ranges",
            "name": "list",
            "key": "list",
            "datatype": "string",
            "operator": "eq",
            "shouldSucceed": true,
            "purpose": "Range index for MarkMail JSON message list"
        }
    ];

    var compareIndexes = function(config, server) {
        if(config.type === "map") {
            equals(config.key, server.key, "Index keys match");
            equals(config.mode, server.mode, "Index modes match");
        }
        else if(config.type === "range") {
            equals(config.key, server.key, "Index keys match");
            equals(config.datatype, server.type, "Index datatypes match");
            equals(config.operator, server.operator, "Index operators match");
        }
        else if(config.type === "bucketedrange") {
            equals(config.key, server.key, "Index keys match");
            equals(config.datatype, server.type, "Index datatypes match");
            equals(config.buckets, server.buckets.join("|"), "Index buckets match");
        }
        else if(config.type === "field") {
            deepEqual(config.includes, server.includedKeys, "Index includes match");
            deepEqual(config.excludes, server.excludedKeys, "Index excludes match");
        }
        else if(config.type === "namespace") {
            equal(config.prefix, server.prefix, "Namespace prefixes match");
            equal(config.uri, server.uri, "Namespace uris match");
        }
    };
    
    var processingPosition = 0;

    var addNextIndex = function() {
        addIndex(processingPosition);
    };

    var addIndex = function(pos) {
        var index = indexes[pos];

        if(index === undefined) {
            asyncTest("Checking created indexes", function() {
                $.ajax({
                    url: '/data/info',
                    context: this,
                    success: function(data) {
                        var info = JSON.parse(data);
                        var i = 0;
                        var j = 0;
                        for (i = 0; i < indexes.length; i += 1) {
                            var config = indexes[i];
                            if(!config.shouldSucceed) {
                                continue;
                            }
                            var foundIndex = false;
                            if(config.type === "namespace") {
                                for(j = 0; j < info.xmlNamespaces.length; j += 1) {
                                    var server = info.xmlNamespaces[j];
                                    if(server.prefix === config.prefix) {
                                        foundIndex = true;
                                        compareIndexes(config, server);
                                    }
                                }
                            }
                            else {
                                for(j = 0; j < info.indexes[config.pluralType].length; j += 1) {
                                    var server = info.indexes[config.pluralType][j];
                                    if(server.name === config.name) {
                                        foundIndex = true;
                                        compareIndexes(config, server);
                                    }
                                }
                            }
                            if(!foundIndex) {
                                ok(false, "Could not find newly added index or namespace");
                            }
                        }
                        callback.call();
                    },
                    error: function() {
                        ok(false, "Could not check for added index or namespace");
                    },
                    complete: function() { start(); }
                });
            });
            return;
        }

        asyncTest(index.purpose, function() {
            var url = "/manage/" + index.type + "/" + index.name;
            var data = {};
            if(index.type === "namespace") {
                url = "/manage/" + index.type + "/" + index.prefix;
                data.uri = index.uri;
            }
            else if(index.type === "map") {
                data.key = index.key;
                data.mode = index.mode;
            }
            else if(index.type === "field") {
                data.includeKey = [];
                data.excludeKey = [];
                data.includeElement = [];
                data.excludeElement = [];

                var i = 0;
                for(i = 0; i < index.includes.length; i += 1) {
                    if(index.includes[i].type === "key") {
                        data.includeKey.push(index.includes[i].name);
                    }
                    else {
                        data.includeElement.push(index.includes[i].name);
                    }
                }
                for(i = 0; i < index.excludes.length; i += 1) {
                    if(index.excludes[i].type === "key") {
                        data.excludeKey.push(index.excludes[i].name);
                    }
                    else {
                        data.excludeElement.push(index.excludes[i].name);
                    }
                }
            }
            else if(index.type === "range") {
                data.key = index.key;
                data.type = index.datatype;
                data.operator = index.operator;
            }
            else if(index.type === "bucketedrange") {
                data.key = index.key;
                data.type = index.datatype;
                data.buckets = index.buckets;
            }

            $.ajax({
                url: url,
                data: data,
                type: 'POST',
                context: index,
                success: function() {
                    ok(true, "Index/namespace was created");
                    processingPosition++;
                    addNextIndex();
                },
                error: function(j, t, error) {
                    ok(!this.shouldSucceed, "Could not add index/namespace: " + error);
                    processingPosition++;
                    addNextIndex();
                },
                complete: function() {
                    start();
                }
            });
        });
    };

    addNextIndex();
};

mljson.insertDocuments = function() {
    var documents = [
        {
            "name1": "Musical Animals",
            "date1::date": "January 5th 1977",
            "included1": "chicken",
            "included2": {
                "animal": "snake",
                "excluded1": "mastodon"
            },
            "uri": "/document1.json"
        },
        {
            "name1": "Other Musical Animals",
            "date1::date": "January 5th 1977",
            "included1": "duck",
            "included2": {
                "animal": "snake",
                "excluded1": "mastodon"
            },
            "uri": "/document2.json"
        },
        {
            "name1": "Other Musical Animals",
            "date1::date": "January 7th 1977",
            "included1": "duck",
            "included2": {
                "animal": "snake",
                "excluded1": "mastodon"
            },
            "uri": "/document3.json"
        }
    ];
    
    var processingPosition = 0;

    var insertNextDocument = function() {
        addDocument(processingPosition);
    };

    var addDocument = function(pos) {
        var doc = documents[pos];

        if(doc === undefined) {
            return;
        }

        asyncTest("Inserting document: " + doc.uri, function() {
            $.ajax({
                url: "/json/store" + doc.uri,
                type: 'PUT',
                data: JSON.stringify(doc),
                success: function() {
                    ok(true, "Inserted document");
                    processingPosition++;
                    insertNextDocument();
                },
                error: function(j, t, error) {
                    ok(false, "Could not insert document");
                    processingPosition++;
                    insertNextDocument();
                },
                complete: function() {
                    start();
                }
            });
        });
    };

    insertNextDocument();
};

$(document).ready(function() {
    module("Database setup");
    asyncTest("Database index setup", function() {
        $.ajax({
            url: '/data/info',
            success: function(data) {
                var info = JSON.parse(data);
                mljson.removeIndexes(info, function() {
                    mljson.addIndexes(function() {
                        mljson.insertDocuments();
                    });
                });
            },
            error: function() {
                ok(false, "Could not fetch server info");
            },
            complete: function() { start(); }
        });
    });
});
