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
                        ok(info.indexes.fields.length === 0 && info.indexes.mappings.length === 0 && info.indexes.ranges.length === 0, "All indexes removed");
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
            var url = "/data/manage/" + index.type + "/" + index.name;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    processingPosition++;
                    ok(true, "Removed the " + index.name + " index");
                    removeNextIndex();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete index" + error);
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
            "includes": ["included1", "included2"],
            "excludes": ["excluded1"],
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
            "purpose": "General range creation"
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
        else if(config.type === "field") {
            deepEqual(config.includes, server.includedKeys, "Index includes match");
            deepEqual(config.excludes, server.excludedKeys, "Index excludes match");
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
                            for(j = 0; j < info.indexes[config.pluralType].length; j += 1) {
                                var server = info.indexes[config.pluralType][j];
                                if(server.name === config.name) {
                                    foundIndex = true;
                                    compareIndexes(config, server);
                                }
                            }
                            if(!foundIndex) {
                                ok(false, "Could not find newly added index");
                            }
                        }
                        callback.call();
                    },
                    error: function() {
                        ok(false, "Could not check for added index");
                    },
                    complete: function() { start(); }
                });
            });
            return;
        }

        asyncTest(index.purpose, function() {
            var url = "/data/manage/" + index.type + "/" + index.name;
            var data = {};
            if(index.type === "map") {
                data.key = index.key;
                data.mode = index.mode;
            }
            else if(index.type === "field") {
                data.include = index.includes;
                data.exclude = index.excludes;
            }
            else if(index.type === "range") {
                data.key = index.key;
                data.type = index.datatype;
                data.operator = index.operator;
            }

            $.ajax({
                url: url,
                data: data,
                type: 'POST',
                context: index,
                success: function() {
                    ok(true, "Index was created");
                    processingPosition++;
                    addNextIndex();
                },
                error: function(j, t, error) {
                    ok(!this.shouldSucceed, "Could not add index: " + error);
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
                url: "/data/store" + doc.uri,
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
