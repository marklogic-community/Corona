if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.removeGeoIndexes = function(info, callback) {
    var i = 0;
    var namespaces = [];
    for(i = 0; i < info.indexes.geo.length; i += 1) {
        namespaces.push(info.indexes.geo[i]);
    }

    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(namespaces[processingPosition]);
    };

    var removeItem = function(geo) {
        if(geo === undefined) {
            callback.call();
            return;
        }

        asyncTest("Remove the " + geo.name + " geo index", function() {
            var url = "/manage/geospatial/" + geo.name;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Removed geo: " + geo.name);
                    asyncTest("Check to make sure the geo index is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Geo index still exists: " + geo.name);
                            },
                            error: function() {
                                ok(true, "Namespace is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    processingPosition++;
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete geo index: " + geo.name + ": " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
};

corona.removeNamespaces = function(info, callback) {
    var i = 0;
    var namespaces = [];
    for(i = 0; i < info.xmlNamespaces.length; i += 1) {
        namespaces.push(info.xmlNamespaces[i]);
    }

    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(namespaces[processingPosition]);
    };

    var removeItem = function(namespace) {
        if(namespace === undefined) {
            callback.call();
            return;
        }

        asyncTest("Remove the " + namespace.prefix + " namespace", function() {
            var url = "/manage/namespace/" + namespace.prefix;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Removed namespace: " + namespace.prefix);
                    asyncTest("Check to make sure the namespace is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Namespace still exists: " + namespace.prefix);
                            },
                            error: function() {
                                ok(true, "Namespace is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    processingPosition++;
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete namespace: " + namespace.prefix + ": " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
};

corona.removeTransformers = function(info, callback) {
    var i = 0;
    var transformers = [];
    for(i = 0; i < info.transformers.length; i += 1) {
        transformers.push(info.transformers[i]);
    }
    
    var processingPosition = 0;
    var removeNextItem = function() {
        removeTransformer(transformers[processingPosition]);
    };

    var removeTransformer = function(transformer) {
        if(transformer === undefined) {
            callback.call();
            return;
        }
        transformer = transformer.name;

        asyncTest("Remove the " + transformer + " transformer", function() {
            var url = "/manage/transformer/" + transformer;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Removed transformer: " + transformer);
                    asyncTest("Check to make sure the transformer is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Transformer still exists: " + transformer);
                            },
                            error: function() {
                                ok(true, "Transformer is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    processingPosition++;
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete transformer: " + transformer + ": " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
}

corona.removeRangeIndexes = function(info, callback) {
    var i = 0;
    var indexes = [];
    for(i = 0; i < info.indexes.ranges.length; i += 1) {
        indexes.push({"type": "range", "name": info.indexes.ranges[i].name});
    }
    for(i = 0; i < info.indexes.bucketedRanges.length; i += 1) {
        indexes.push({"type": "bucketedrange", "name": info.indexes.bucketedRanges[i].name});
    }

    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(indexes[processingPosition]);
    };

    var removeItem = function(index) {
        if(index === undefined) {
            callback.call();
            return;
        }

        asyncTest("Remove the " + index.name + " range index", function() {
            var url = "/manage/" + index.type + "/" + index.name;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Removed range index: " + index.name);
                    asyncTest("Check to make sure the range index is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Range index still exists: " + index.name);
                            },
                            error: function() {
                                ok(true, "Range index is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    processingPosition++;
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete range index: " + index.name + ": " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
}

corona.removeAnonymousPlaces = function(info, callback) {
    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(info.indexes.anonymousPlace.places[processingPosition]);
        processingPosition++;
    };

    var removeItem = function(place) {
        if(place === undefined) {
            asyncTest("Check to make sure the anonymous places are gone", function() {
                $.ajax({
                    url: "/manage/place",
                    success: function(config) {
                        equals(0, config.places.length, "Number of anonymous places remaining");
                        callback.call();
                    },
                    error: function() {
                        ok(false, "Could not fetch anonymous place definition");
                    },
                    complete: function() { start(); }
                });
            });

            return;
        }

        var url = "/manage/place?";
        var params = [];
        if(place.key !== undefined) {
            params.push("key=" + escape(place.key))
        }
        if(place.element !== undefined) {
            params.push("element=" + escape(place.element));
        }
        if(place.attribute !== undefined) {
            params.push("attribute=" + escape(place.attribute));
        }
        if(place.place !== undefined) {
            params.push("place=" + escape(place.place));
        }
        if(place.type !== undefined) {
            params.push("type=" + escape(place.type));
        }
        if(params.length) {
            url += params.join("&");
        }
        asyncTest("Remove the anonymous place: " + url, function() {
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Deleted the anonymous place");
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete anonymous place: " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
};

corona.removePlaces = function(info, callback) {
    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(info.indexes.places[processingPosition]);
        processingPosition++;
    };

    var removeItem = function(place) {
        if(place === undefined) {
            callback.call();
            return;
        }

        if(place.name === "") {
            removeNextItem();
        }

        var url = "/manage/place/" + place.name;
        asyncTest("Remove the place: " + place.name, function() {
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Deleted the place: " + place.name);
                    asyncTest("Check to make sure the place is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Place still exists");
                            },
                            error: function() {
                                ok(true, "Place is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete place: " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
};

corona.addNamespaces = function(callback) {
    var namespaces = [
        {
            "type": "namespace",
            "prefix": "test:ns",
            "uri": "http://test.ns/uri",
            "shouldSucceed": false,
            "purpose": "Should fail with invalid XML namespace prefix"
        },
        {
            "type": "namespace",
            "prefix": "testns",
            "uri": "http://test.ns/uri",
            "shouldSucceed": true,
            "purpose": "Creation of XML namespace"
        }
    ];

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(namespaces[processingPosition]);
        processingPosition++;
    };

    var addItem = function(namespace) {
        if(namespace === undefined) {
            callback.call();
            return;
        }

        asyncTest(namespace.purpose, function() {
            var url = "/manage/namespace/" + namespace.prefix;
            var data = {"uri": namespace.uri};
            $.ajax({
                url: url,
                data: data,
                type: "POST",
                success: function() {
                    if(namespace.shouldSucceed) {
                        ok(true, "Namespace was created");
                        asyncTest("Checking to make sure the namespace was created correctly", function() {
                            $.ajax({
                                url: url,
                                success: function(info) {
                                    equal(namespace.prefix, info.prefix, "Namespace prefixes matches");
                                    equal(namespace.uri, info.uri, "Namespace uris matches");
                                },
                                error: function() {
                                    ok(false, "Could not check for added namespace");
                                },
                                complete: function() { start(); }
                            });
                        });
                    }
                    else {
                        ok(false, "Namespace was created when it should have errored");
                    }
                    addNextItem();
                },
                error: function(j, t, error) {
                    ok(!namespace.shouldSucceed, "Could not add namespace: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

corona.addRangeIndexes = function(callback) {
    var indexes = [
        {
            "type": "range",
            "name": "list",
            "key": "list",
            "datatype": "string",
            "collation": "codepoint",
            "shouldSucceed": true,
            "purpose": "Range index for MarkMail JSON message list"
        },
        {
            "type": "range",
            "name": "range1",
            "key": "date1::date",
            "datatype": "date",
            "shouldSucceed": true,
            "purpose": "JSON range creation on a date"
        },
        {
            "type": "range",
            "name": "range2",
            "key": "rangeKey",
            "datatype": "string",
            "shouldSucceed": true,
            "purpose": "JSON range creation on a string"
        },
        {
            "type": "range",
            "name": "range3",
            "key": "rangeKey",
            "datatype": "number",
            "shouldSucceed": true,
            "purpose": "JSON range creation on a number"
        },
        {
            "type": "range",
            "name": "range4",
            "element": "rangeKey",
            "datatype": "string",
            "shouldSucceed": true,
            "purpose": "XML element range creation on a string"
        },
        {
            "type": "range",
            "name": "range5",
            "element": "testns:rangeEl",
            "datatype": "string",
            "shouldSucceed": true,
            "purpose": "Namespaced XML element range creation on a string"
        },
        {
            "type": "range",
            "name": "range6",
            "element": "testns:rangeEl",
            "attribute": "rangeAttrib",
            "datatype": "string",
            "shouldSucceed": true,
            "purpose": "Namespaced XML element attribute range creation on a string"
        },
        {
            "type": "range",
            "name": "range7",
            "element": "testns:rangeEl",
            "datatype": "dateTime",
            "shouldSucceed": true,
            "purpose": "Namespaced XML element range creation on a dateTime"
        },
        {
            "type": "range",
            "name": "range8",
            "element": "invalidns:rangeEl",
            "attribute": "rangeAttrib",
            "datatype": "string",
            "shouldSucceed": false,
            "purpose": "Invalid XML element on a element attribute range index"
        },
        {
            "type": "range",
            "name": "range9",
            "element": "rangeEl",
            "attribute": "invalidns:rangeAttrib",
            "datatype": "string",
            "shouldSucceed": false,
            "purpose": "Invalid XML element on a element attribute range index"
        },
        {
            "type": "range",
            "name": "list",
            "key": "name1",
            "datatype": "string",
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a range"
        },

        // Bucketed ranges
        {
            "type": "bucketedrange",
            "name": "fromBucket",
            "key": "fromPersonal",
            "datatype": "string",
            "buckets": "A-F|G|G-M|N|N-R|S|S-Z",
            "shouldSucceed": true,
            "purpose": "JSON key bucketed range creation on a string"
        },
        {
            "type": "bucketedrange",
            "name": "fromBucketXML",
            "element": "from",
            "attribute": "personal",
            "datatype": "string",
            "buckets": "A-F|G|G-M|N|N-R|S|S-Z",
            "shouldSucceed": true,
            "purpose": "Element/attribute bucketed range creation on a string"
        },
        {
            "type": "bucketedrange",
            "name": "messageDate",
            "key": "date::date",
            "datatype": "date",
            "startingAt": "1970-01-01T00:00:00-07:00",
            "firstFormat": "Before %b %d %Y",
            "format": "%b %d %Y - @b @d @Y",
            "lastFormat": "After %b %d %Y",
            "bucketInterval": "month",
            "shouldSucceed": true,
            "purpose": "Auto-bucketed range index for MarkMail JSON message date"
        },
        {
            "type": "bucketedrange",
            "name": "list",
            "key": "date::date",
            "datatype": "date",
            "startingAt": "1970-01-01T00:00:00-07:00",
            "firstFormat": "Before %b %d %Y",
            "format": "%b %d %Y - @b @d @Y",
            "lastFormat": "After %b %d %Y",
            "bucketInterval": "month",
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a bucketed range"
        }
    ];

    var compareIndexes = function(config, server) {
        if(config.type === "range") {
            if(config.key !== undefined) {
                equals(config.key, server.key, "Index key matches");
            }
            if(config.element !== undefined) {
                equals(config.element, server.element, "Index element matches");
            }
            if(config.attribute !== undefined) {
                equals(config.attribute, server.attribute, "Index attribute matches");
            }
            equals(config.datatype, server.type, "Index datatype matches");
            if(config.collation !== undefined) {
                equals(config.collation, server.collation, "Index collation matches");
            }
        }
        else if(config.type === "bucketedrange") {
            equals(config.datatype, server.type, "Index datatype matches");
            if(config.collation !== undefined) {
                equals(config.collation, server.collation, "Index collation matches");
            }
            if(config.key !== undefined) {
                equals(config.key, server.key, "Index key matches");
            }
            if(config.element !== undefined) {
                equals(config.element, server.element, "Index element matches");
            }
            if(config.attribute !== undefined) {
                equals(config.attribute, server.attribute, "Index attribute matches");
            }
            if(config.buckets !== undefined) {
                equals(config.buckets, server.buckets.join("|"), "Index buckets matches");
            }
            if(config.startingAt !== undefined) {
                equals(config.startingAt, server.startingAt, "Index starting date matches");
            }
            if(config.stoppingAt !== undefined) {
                equals(config.stoppingAt, server.stoppingAt, "Index stopping date matches");
            }
            if(config.bucketInterval !== undefined) {
                equals(config.bucketInterval, server.bucketInterval, "Index bucketInterval matches");
            }
            if(config.firstFormat !== undefined) {
                equals(config.firstFormat, server.firstFormat, "Index firstFormat matches");
            }
            if(config.format !== undefined) {
                equals(config.format, server.format, "Index format matches");
            }
            if(config.lastFormat !== undefined) {
                equals(config.lastFormat, server.lastFormat, "Index lastFormat matches");
            }
        }
    };

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(indexes[processingPosition]);
        processingPosition++;
    };

    var addItem = function(index) {
        if(index === undefined) {
            callback.call();
            return;
        }

        asyncTest(index.purpose, function() {
            var url = "/manage/" + index.type + "/" + index.name;
            var data = {};
            if(index.type === "range") {
                data.key = index.key;
                data.element = index.element;
                data.attribute = index.attribute;
                data.type = index.datatype;
                data.collation = index.collation;
            }
            else if(index.type === "bucketedrange") {
                data.type = index.datatype;
                data.collation = index.collation;
                data.key = index.key;
                data.element = index.element;
                data.attribute = index.attribute;
                data.buckets = index.buckets;
                data.startingAt = index.startingAt;
                data.stoppingAt = index.stoppingAt;
                data.bucketInterval = index.bucketInterval;
                data.firstFormat = index.firstFormat;
                data.format = index.format;
                data.lastFormat = index.lastFormat;
            }

            $.ajax({
                url: url,
                data: data,
                type: "POST",
                success: function() {
                    if(index.shouldSucceed) {
                        ok(true, "Range index was created");
                        asyncTest("Checking to make sure the range index was created correctly", function() {
                            $.ajax({
                                url: url,
                                success: function(info) {
                                    compareIndexes(index, info);
                                },
                                error: function() {
                                    ok(false, "Could not check for added range index");
                                },
                                complete: function() { start(); }
                            });
                        });
                    }
                    else {
                        ok(false, "Range index was created when it should have errored");
                    }
                    addNextItem();
                },
                error: function(j, t, error) {
                    ok(!index.shouldSucceed, "Could not add range index: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

corona.addTransformers = function(callback) {
    var transformers = [
        {
            "type": "transformer",
            "name": "generic",
            "transformer": '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:template match="/"><div>XSLT\'d!</div></xsl:template></xsl:stylesheet>',
            "shouldSucceed": true,
            "purpose": "Storing a XSLT transformer"
        },
        {
            "type": "transformer",
            "name": "xqtrans",
            "transformer": 'xquery version "1.0-ml"; declare variable $content as node()? external; <div>XQuery\'d!</div>',
            "shouldSucceed": true,
            "purpose": "Storing a XQuery transformer"
        },
        {
            "type": "transformer",
            "name": "adddate",
            "transformer": 'xquery version "1.0-ml"; declare variable $content as node()? external; <wrapper date="{ current-dateTime() }">{ $content }</wrapper>',
            "shouldSucceed": true,
            "purpose": "Storing another XQuery transformer"
        }
    ];

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(transformers[processingPosition]);
        processingPosition++;
    };

    var addItem = function(transformer) {
        if(transformer === undefined) {
            callback.call();
            return;
        }

        asyncTest(transformer.purpose, function() {
            var url = "/manage/transformer/" + transformer.name;
            var data = transformer.transformer;
            $.ajax({
                url: url,
                data: data,
                type: "PUT",
                success: function() {
                    if(transformer.shouldSucceed) {
                        ok(true, "Transformer was created");
                    }
                    else {
                        ok(false, "Transformer was created when it should have errored");
                    }
                    addNextItem();
                },
                error: function(j, t, error) {
                    ok(!transformer.shouldSucceed, "Could not add transformer: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

corona.addPlaces = function(callback) {
    var places = [
        // Anonymous place configuration
        {
            "type": "place",
            "name": "",
            "places": [
                { "key": "subject", "type": "include", "weight": 10},
                { "element": "testns:subject", "type": "include", "weight": 8},
                { "element": "testns:subject", "attribute": "normalized", "type": "include", "weight": 8},
                { "key": "tri=ck|ey", "type": "include", "weight": 10}
            ],
            "shouldSucceed": true,
            "purpose": "Anonymous place configuration with keys, element and attribute"
        },

        // Named places
        {
            "type": "place",
            "name": "place1",
            "places": [
                { "key": "included1", "type": "include", "weight": 10},
                { "key": "included2", "type": "include", "weight": 9},
                { "element": "nonselment", "type": "include", "weight": 8},
                { "element": "testns:nselement", "type": "include", "weight": 7},
                { "key": "excluded1", "type": "exclude"},
                { "element": "excludenonsel", "type": "exclude"},
                { "element": "testns:excludensel", "type": "exclude"}
            ],
            "shouldSucceed": true,
            "purpose": "Place with includes and excludes of JSON keys and XML elements, with and without namespaces",
        },
        {
            "type": "place",
            "name": "place2",
            "places": [
                { "key": "included1", "type": "include"},
                { "place": "place1", "type": "include"}
            ],
            "shouldSucceed": true,
            "purpose": "Place with sub-place",
        },

        {
            "type": "place",
            "name": "place3",
            "places": [
                { "key": "included1", "type": "include"},
                { "key": "included1", "type": "include", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (key, include)",
        },
        {
            "type": "place",
            "name": "place4",
            "places": [
                { "key": "included1", "type": "include"},
                { "key": "excluded1", "type": "exclude"},
                { "key": "excluded1", "type": "exclude", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (key, exclude)",
        },
        {
            "type": "place",
            "name": "place5",
            "places": [
                { "element": "included1", "type": "include"},
                { "element": "included1", "type": "include", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (element, include)",
        },
        {
            "type": "place",
            "name": "place6",
            "places": [
                { "element": "included1", "type": "include"},
                { "element": "excluded1", "type": "exclude"},
                { "element": "excluded1", "type": "exclude", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (element, exclude)",
        },
        {
            "type": "place",
            "name": "place7",
            "places": [
                { "element": "included1", "attribute": "norm"},
                { "element": "included1", "attribute": "norm", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (attribute)",
        },
        {
            "type": "place",
            "name": "place8",
            "places": [
                { "place": "place1"},
                { "place": "place1", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Detecting duplicate items in a place (place)",
        },

        {
            "type": "place",
            "name": "place9",
            "mode": "equals",
            "places": [
                { "key": "included1", "type": "include"}
            ],
            "shouldSucceed": false,
            "purpose": "Place with includes and a mode of equals (unsupported mode)",
        },
        {
            "type": "place",
            "name": "place10",
            "places": [
                { "element": "invalidns:included1", "type": "include", "shouldSucceed": false}
            ],
            "shouldSucceed": true,
            "purpose": "Checking for bogus XML element names"
        },
        {
            "type": "place",
            "name": "place1",
            "places": [
                { "key": "included1", "type": "include"}
            ],
            "shouldSucceed": false,
            "purpose": "Making sure you can't have duplicate names when creating a place"
        }
    ];

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(places[processingPosition]);
        processingPosition++;
    };

    var addItem = function(place) {
        if(place === undefined) {
            callback.call();
            return;
        }

        asyncTest(place.purpose, function() {
            var url = "/manage/place/" + place.name;
            var extras = [];
            if(place.mode) {
                extras.push("mode=" + place.mode);
            }
            if(extras.length) {
                url += "?" + extras.join("&");
            }
            $.ajax({
                url: url,
                type: "PUT",
                success: function() {
                    if(place.shouldSucceed) {
                        ok(true, "Place " + place.name + " was created");

                        var items = place.places;
                        var processingItemPosition = 0;
                        var addNextPlaceItem = function() {
                            addPlaceItem(items[processingItemPosition], processingItemPosition);
                            processingItemPosition++;
                        };

                        var addPlaceItem = function(item, pos) {
                            if(item === undefined) {
                                return;
                            }

                            if(item.shouldSucceed === undefined) {
                                item.shouldSucceed = true;
                            }

                            asyncTest("Adding an item into the place: " + place.name,  function() {

                                var data = {};
                                data.key = item.key;
                                data.element = item.element;
                                data.attribute = item.attribute;
                                data.place = item.place;
                                data.type = item.type;
                                data.weight = item.weight;

                                $.ajax({
                                    url: url,
                                    data: data,
                                    type: "POST",
                                    success: function(data) {
                                        ok(item.shouldSucceed, "Item was added to place");
                                        if(pos === place.places.length - 1) {
                                            asyncTest("Checking to make sure the place items were created correctly", function() {
                                                $.ajax({
                                                    url: url,
                                                    success: function(info) {
                                                        $(place.places).each(function(index, configItem) {
                                                            if(configItem.shouldSucceed === false) {
                                                                return;
                                                            }

                                                            var found = false;
                                                            $(info.places).each(function(index, serverItem) {
                                                                if(configItem.key == serverItem.key &&
                                                                    configItem.element == serverItem.element &&
                                                                    configItem.attribute == serverItem.attribute &&
                                                                    configItem.place == serverItem.place) {

                                                                    found = true;
                                                                    if(configItem.weight !== undefined) {
                                                                        equals(configItem.weight, serverItem.weight, "Item weight");
                                                                    }
                                                                }
                                                            });
                                                            ok(found, "Found configured item");
                                                        });

                                                        if(place.mode !== undefined) {
                                                            equals(place.mode, info.mode, "Place mode matches");
                                                        }
                                                    },
                                                    error: function(j, t, error) {
                                                        ok(false, "Could not check if the item was added to the place: " + error);
                                                    },
                                                    complete: function() { start(); }
                                                });
                                            });
                                        }
                                        addNextPlaceItem();
                                    },
                                    error: function(j, t, error) {
                                        ok(!item.shouldSucceed, "Could not item add place: " + error);
                                    },
                                    complete: function() { start(); }
                                });
                            });
                        }

                        addNextPlaceItem();
                    }
                    else {
                        ok(false, "Place was created when it should have errored");
                    }
                    addNextItem();
                },
                error: function(j, t, error) {
                    ok(!place.shouldSucceed, "Could not add place: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

corona.addGeoIndexes = function(callback) {
    var geoIndexes = [
        // Key
        {
            "type": "geo",
            "name": "geokey",
            "key": "latLongKey",
            "shouldSucceed": true,
            "purpose": "Geo key"
        },

        // Element
        {
            "type": "geo",
            "name": "geoelement",
            "element": "latLongElement",
            "shouldSucceed": true,
            "purpose": "Geo element"
        },

        // Child key
        {
            "type": "geo",
            "name": "geochildkey",
            "parentKey": "parentKey",
            "key": "latLongKey",
            "shouldSucceed": true,
            "purpose": "Geo child key"
        },

        // Child element
        {
            "type": "geo",
            "name": "geochildelement",
            "parentElement": "parentElement",
            "element": "latLongElement",
            "shouldSucceed": true,
            "purpose": "Geo child element"
        },

        // Child key pair
        {
            "type": "geo",
            "name": "geochildpairkey",
            "parentKey": "parentKey",
            "latKey": "latKey",
            "longKey": "longKey",
            "shouldSucceed": true,
            "purpose": "Geo key pair"
        },

        // Child element pair
        {
            "type": "geo",
            "name": "geochildpairelement",
            "parentElement": "parentElement",
            "latElement": "latElement",
            "longElement": "longElement",
            "shouldSucceed": true,
            "purpose": "Geo element pair"
        },

        // Attribute pair
        {
            "type": "geo",
            "name": "geoattribute",
            "parentElement": "parentElement",
            "latAttribute": "latAttribute",
            "longAttribute": "longAttribute",
            "shouldSucceed": true,
            "purpose": "Geo element attribute pair"
        }
    ];

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(geoIndexes[processingPosition]);
        processingPosition++;
    };

    var addItem = function(geoIndex) {
        if(geoIndex === undefined) {
            callback.call();
            return;
        }

        asyncTest(geoIndex.purpose, function() {
            var url = "/manage/geospatial/" + geoIndex.name;
            var data = {};

            data.key = geoIndex.key;
            data.element = geoIndex.element;
            data.parentKey = geoIndex.parentKey;
            data.parentElement = geoIndex.parentElement;
            data.latKey = geoIndex.latKey;
            data.longKey = geoIndex.longKey;
            data.latElement = geoIndex.latElement;
            data.longElement = geoIndex.longElement;
            data.latAttribute = geoIndex.latAttribute;
            data.longAttribute = geoIndex.longAttribute;
            data.coordinateSystem = geoIndex.coordinateSystem;
            data.comesFirst = geoIndex.comesFirst;

            $.ajax({
                url: url,
                data: data,
                type: "POST",
                success: function() {
                    if(geoIndex.shouldSucceed) {
                        ok(true, "Geo index " + geoIndex.name + " was created");

                        asyncTest("Checking to make sure the geo index was created correctly", function() {
                            $.ajax({
                                url: url,
                                success: function(info) {
                                    if(geoIndex.key) { equals(geoIndex.key, info.key, "Key matches"); }
                                    if(geoIndex.element) { equals(geoIndex.element, info.element, "Element matches"); }
                                    if(geoIndex.parentKey) { equals(geoIndex.parentKey, info.parentKey, "Parent key matches"); }
                                    if(geoIndex.parentElement) { equals(geoIndex.parentElement, info.parentElement, "Parent element matches"); }
                                    if(geoIndex.latKey) { equals(geoIndex.latKey, info.latKey, "Latitude key matches"); }
                                    if(geoIndex.longKey) { equals(geoIndex.longKey, info.longKey, "Longitude key matches"); }
                                    if(geoIndex.latElement) { equals(geoIndex.latElement, info.latElement, "Latitude element matches"); }
                                    if(geoIndex.longElement) { equals(geoIndex.longElement, info.longElement, "Longitude element matches"); }
                                    if(geoIndex.latAttribute) { equals(geoIndex.latAttribute, info.latAttribute, "Latitude attribute matches"); }
                                    if(geoIndex.longAttribute) { equals(geoIndex.longAttribute, info.longAttribute, "Longitude attribute matches"); }
                                    if(geoIndex.coordinateSystem) { equals(geoIndex.coordinateSystem, info.coordinateSystem, "Coordinate system matches"); }
                                    if(geoIndex.comesFirst) { equals(geoIndex.comesFirst, info.comesFirst, "Comes first matches"); }
                                },
                                error: function(j, t, error) {
                                    ok(false, "Could not check if the item was added to the place: " + error);
                                },
                                complete: function() { start(); }
                            });
                        });
                    }
                    else {
                        ok(false, "Geo index was created when it should have errored");
                    }
                    addNextItem();
                },
                error: function(j, t, error) {
                    ok(!geoIndex.shouldSucceed, "Could not add geo index: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

$(document).ready(function() {
    module("Database setup");
    asyncTest("Database index setup", function() {
        $.ajax({
            url: '/manage',
            success: function(info) {
                corona.removeTransformers(info, function() {
                    corona.removeRangeIndexes(info, function() {
                        corona.removeAnonymousPlaces(info, function() {
                            corona.removeGeoIndexes(info, function() {
                                corona.removePlaces(info, function() {
                                    corona.removeNamespaces(info, function() {
                                        corona.addNamespaces(function() {
                                            corona.addTransformers(function() {
                                                corona.addRangeIndexes(function() {
                                                    corona.addPlaces(function() {
                                                        corona.addGeoIndexes(function() {
                                                        });
                                                    });
                                                });
                                            });
                                        });
                                    });
                                });
                            });
                        });
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
