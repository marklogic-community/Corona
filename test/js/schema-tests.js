if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.removeSchemas = function(info, callback) {
    var i = 0;
    var schemas = [];
    for(i = 0; i < info.xmlSchemas.length; i += 1) {
        schemas.push(info.xmlSchemas[i]);
    }

    var processingPosition = 0;
    var removeNextItem = function() {
        removeItem(schemas[processingPosition]);
        processingPosition++;
    };

    var removeItem = function(schema) {
        if(schema === undefined) {
            callback.call();
            return;
        }

        asyncTest("Remove the schema: " + schema, function() {
            var url = "/manage/schema?uri=" + schema;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    ok(true, "Removed schema: " + schema);
                    asyncTest("Check to make sure the schema is gone", function() {
                        $.ajax({
                            url: url,
                            success: function(data) {
                                ok(false, "Schema still exists: " + schema);
                            },
                            error: function() {
                                ok(true, "Schema is gone");
                            },
                            complete: function() { start(); }
                        });
                    });
                    removeNextItem();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete schema: " + schema + ": " + error);
                },
                complete: function() { start(); }
            });
        });
    }

    removeNextItem();
};

corona.addSchemas = function(callback) {
    var schemas = [
        {
            "uri": "/schema/foo.xs",
            "schema": '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="foo"><xs:complexType><xs:sequence><xs:element name="bar" type="xs:string"/><xs:element name="baz" type="xs:string"/></xs:sequence></xs:complexType></xs:element></xs:schema>',
            "shouldSucceed": true
        }
    ];

    var processingPosition = 0;
    var addNextItem = function() {
        addItem(schemas[processingPosition]);
        processingPosition++;
    };

    var addItem = function(schema) {
        if(schema === undefined) {
            callback.call();
            return;
        }

        asyncTest("PUT: " + schema.uri, function() {
            $.ajax({
                url: "/manage/schema?uri=" + schema.uri,
                data: schema.schema,
                type: "PUT",
                success: function() {
                    addNextItem();
                    ok(schema.shouldSucceed, "Schema added: " + schema.uri);
                },
                error: function(j, t, error) {
                    ok(!schema.shouldSucceed, "Could not add schema: " + error);
                    addNextItem();
                },
                complete: function() { start(); }
            });
        });
    };

    addNextItem();
};

$(document).ready(function() {
    module("Schemas");
    asyncTest("Schema tests", function() {
        $.ajax({
            url: '/manage',
            success: function(info) {
                corona.removeSchemas(info, function() {
                    corona.addSchemas(function() {
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
