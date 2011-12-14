if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.namedQueries = [
    {
        name: "query1",
        purpose: "Basic string query",
        storeParams: {
            description: "Hello world string query",
            stringQuery: "hello world"
        },
        getParams: {
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query1", "Correct name was found");
            equals(data.results[0].queryType, "string", "Correct query type was found");
        }
    },
    {
        name: "query2",
        purpose: "Basic structured query",
        storeParams: {
            description: "Hello world structured query",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"})
        },
        getParams: {
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query2", "Correct name was found");
            equals(data.results[0].queryType, "structured", "Correct query type was found");
        }
    },
    {
        name: "query3",
        purpose: "Query with collection",
        storeParams: {
            description: "Query in collection",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"}),
            collection: "namedQueryCollection1"
        },
        getParams: {
            collection: "namedQueryCollection1"
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query3", "Correct name was found");
            equals(data.results[0].queryType, "structured", "Correct query type was found");
        }
    },
    {
        name: "query4",
        purpose: "Query with property",
        storeParams: {
            description: "Query with property",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"}),
            property: "querykey:foobar"
        },
        getParams: {
            property: "querykey",
            value: "foobar"
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query4", "Correct name was found");
            equals(data.results[0].queryType, "structured", "Correct query type was found");
        }
    },
];

corona.storeQuery = function(definition) {
    asyncTest(definition.purpose, function() {
        $.ajax({
            url: "/namedquery/" + definition.name,
            type: 'POST',
            data: definition.storeParams,
            success: function() {
                ok(definition.shouldSucceed, "Named query storage succeded");
                if(definition.shouldSucceed === false) {
                    return;
                }

                url = "/namedquery";
                if(definition.getParams.collection === undefined && definition.getParams.property === undefined) {
                    url += "/" + definition.name;
                }
                
                $.ajax({
                    url:  url,
                    type: 'GET',
                    data: definition.getParams,
                    success: function(data) {
                        ok(true, "Fetched named query");
                        if(definition.assert !== undefined) {
                            definition.assert.call(this, data);
                        }
                        $.ajax({
                            url: "/namedquery/" + definition.name,
                            type: 'DELETE',
                            success: function() {
                                ok(true, "Deleted named query");
                            },
                            error: function() {
                                ok(false, "Deleted named query");
                            }
                        });
                    },
                    error: function(j, t, error) {
                        ok(false, "Fetching named query");
                    },
                    complete: function() {
                        start();
                    }
                });
            },
            error: function(j, t, error) {
                ok(!definition.shouldSucceed, "Named query storage failed");
            }
        });
    });
};

corona.removePrefix = function(prefix, callback) {
    $.ajax({
        url: "/manage/namedqueryprefix/" + prefix,
        type: 'GET',
        success: function() {
            $.ajax({
                url: "/manage/namedqueryprefix/" + prefix,
                type: 'DELETE',
                success: function() {
                    callback.call();
                }
            });
        },
        error: function() {
            callback.call();
        }
    });
}

$(document).ready(function() {
    module("Named Queries");

    for(i = 0; i < corona.namedQueries.length; i += 1) {
        corona.storeQuery(corona.namedQueries[i]);
    }

    corona.removePrefix("zip", function() {
        $.ajax({
            url: "/manage/namedqueryprefix/zip",
            type: 'POST',
            success: function() {
                $.ajax({
                    url: "/namedquery/zip:94402",
                    type: 'POST',
                    data: {
                        structuredQuery: JSON.stringify({
                            "geo": "geokey",
                            "region": {
                                "point": {
                                    "latitude": 37.554167,
                                    "longitude": -122.31305610
                                }
                            }
                        })
                    }
                });
            }
        });
    });

});
