if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.namedQueries = [
    {
        purpose: "Basic string query",
        storeParams: {
            name: "query1",
            description: "Hello world string query",
            stringQuery: "hello world"
        },
        getParams: {
            name: "query1"
        },
        deleteParams: {
            name: "query1"
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query1", "Correct name was found");
            equals(data.results[0].queryType, "string", "Correct query type was found");
        }
    },
    {
        purpose: "Basic structured query",
        storeParams: {
            name: "query2",
            description: "Hello world structured query",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"})
        },
        getParams: {
            name: "query2"
        },
        deleteParams: {
            name: "query2"
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query2", "Correct name was found");
            equals(data.results[0].queryType, "structured", "Correct query type was found");
        }
    },
    {
        purpose: "Query with collection",
        storeParams: {
            name: "query3",
            description: "Query in collection",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"}),
            collection: "namedQueryCollection1"
        },
        getParams: {
            collection: "namedQueryCollection1"
        },
        deleteParams: {
            name: "query3"
        },
        shouldSucceed: true,
        assert: function(data) {
            equals(data.results.length, 1, "Got one document");
            equals(data.results[0].name, "query3", "Correct name was found");
            equals(data.results[0].queryType, "structured", "Correct query type was found");
        }
    },
    {
        purpose: "Query with property",
        storeParams: {
            name: "query4",
            description: "Query with property",
            structuredQuery: JSON.stringify({wordAnywhere: "hello world"}),
            property: "querykey:foobar"
        },
        getParams: {
            property: "querykey",
            value: "foobar"
        },
        deleteParams: {
            name: "query4"
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
            url: "/namedquery",
            type: 'POST',
            data: definition.storeParams,
            success: function() {
                ok(definition.shouldSucceed, "Named query storage succeded");
                if(definition.shouldSucceed === false) {
                    return;
                }

                $.ajax({
                    url:  "/namedquery",
                    type: 'GET',
                    data: definition.getParams,
                    success: function(data) {
                        ok(true, "Fetched named query");
                        if(definition.assert !== undefined) {
                            definition.assert.call(this, data);
                        }
                        $.ajax({
                            url: "/namedquery?name=" + encodeURIComponent(definition.deleteParams.name),
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

$(document).ready(function() {
    module("Named Queries");
    for(i = 0; i < corona.namedQueries.length; i += 1) {
        corona.storeQuery(corona.namedQueries[i]);
    }
});
