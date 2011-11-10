if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}


corona.badJSON = [
    {
        "jsonString": "[1 2]",
        "error": "Unexpected token number: '[1 2]'. Expected either a comma or closing array",
        "purpose": "Missing commas in arrays"
    },
    {
        "jsonString": "{\"foo\" \"bar\"}",
        "error": "Unexpected token string: '{\"foo\" \"bar\"}'. Expected a colon",
        "purpose": "Missing colons in objects"
    },
    {
        "jsonString": "[1, 2",
        "error": "Unexpected token : '1, 2'. Expected either a comma or closing array",
        "purpose": "Missing brackets in arrays"
    },
    {
        "jsonString": "[1.2.2]",
        "error": "Unexpected token error: '[1.2.2]'. Expected either a comma or closing array",
        "purpose": "Too many periods in a number"
    }
];

corona.validJSON = [
    {
        "json": true,
        "purpose": "Primitive true"
    },
    {
        "json": false,
        "purpose": "Primitive false"
    },
    {
        "json": [],
        "purpose": "Empty array"
    },
    {
        "json": null,
        "purpose": "Primitive null"
    },
    {
        "json": {},
        "purpose": "Empty object"
    },
    {
        "json": -1,
        "purpose": "Negative numbers"
    },
    {
        "json": 1.2,
        "purpose": "Floating points"
    },
    {
        "json": ["hello", "world", [], {}, null, false, true],
        "purpose": "General array with all data types"
    },
    {
        "json": {"": "bar"},
        "purpose": "Key with zero length"
    },
    {
        "json": {"_foo": "bar"},
        "purpose": "Meta escaping (escaping our invalid xml element name escaping)"
    },
    {
        "json": {"f•o": "bar"},
        "purpose": "Unicode chars in the key"
    },
    {
        "json": {"key with spaces": true},
        "purpose": "Keys with spaces"
    },
    {
        "json": {"foo": "bar\nbaz"},
        "purpose": "Newlines in strings"
    },
    {
        "json": {"foo": "\"bar\""},
        "purpose": "Double quotes in strings"
    },
    {
        "json": {"foo": "'bar'"},
        "purpose": "Single quotes in strings"
    },
    {
        "json": {"foo": "", "bar": ""},
        "purpose": "Object value strings with zero length"
    },
    {
        "json": {"text": "ぐらまぁでちゅね♥おはようです！"},
        "purpose": "Unicode value strings"
    },
    {
        "json": {"text": "\u3050\u3089\u307e\u3041\u3067\u3061\u3085\u306d\u2665\u304a\u306f\u3088\u3046\u3067\u3059\uff01"},
        "purpose": "Escaped unicode strings"
    },
    {
        "json": [1, 2, 3, [4, 5, [ 7, 8, 9], 6]],
        "purpose": "Nexted arrays"
    },
    {
        "json": [1, 2, 3, [4, 5, [7, 8, 9], 6], 10],
        "purpose": "Nested arrays with trailing values"
    },
    {
        "json": {
            "foo": 1,
            "bar": {"baz": 2, "yaz": 3}
        },
        "purpose": "Nested objects"
    },
    {
        "json": {
            "foo": 1,
            "em": {"a": "b"},
            "bar": "aa"
        },
        "purpose": "Nested objects with trailing key/value"
    },
    {
        "json": {"false": "false"},
        "purpose": "false as a key/value"
    },
    {
        "json": {"foo::xml": "<foo><bar/></foo>"},
        "purpose": "Cast an object value as XML"
    },
    {
        "json": {"foo::date": "Thu Jul 07 2011 11:05:42 GMT-0700 (PDT)"},
        "purpose": "Date parsing: Thu Jul 07 2011 11:05:42 GMT-0700 (PDT)"
    },
    {
        "json": {"foo::date": "25-Oct-2004 17:06:46 -0500"},
        "purpose": "Date parsing: 25-Oct-2004 17:06:46 -0500"
    },
    {
        "json": {"foo::date": "Mon, 23 Sep 0102 23:14:26 +0900"},
        "purpose": "Date parsing: Mon, 23 Sep 0102 23:14:26 +0900"
    },
    {
        "json": {"foo::date": "30 Jun 2006 09:39:08 -0500"},
        "purpose": "Date parsing: 30 Jun 2006 09:39:08 -0500"
    },
    {
        "json": {"foo::date": "Apr 16 13:49:06 2003 +0200"},
        "purpose": "Date parsing: Apr 16 13:49:06 2003 +0200"
    },
    {
        "json": {"foo::date": "Aug 04 11:44:58 EDT 2003"},
        "purpose": "Date parsing: Aug 04 11:44:58 EDT 2003"
    },
    {
        "json": {"foo::date": "4 Jan 98 0:41 EDT"},
        "purpose": "Date parsing: 4 Jan 98 0:41 EDT"
    },
    {
        "json": {"foo::date": "08-20-2007"},
        "purpose": "Date parsing: 08-20-2007"
    },
    {
        "json": {"foo::date": "08-20-07"},
        "purpose": "Date parsing: 08-20-07"
    },
    {
        "json": {"foo::date": "2007/08/20"},
        "purpose": "Date parsing: 2007/08/20"
    },
    {
        "json": {"foo::date": "07/08/20"},
        "purpose": "Date parsing: 07/08/20"
    },
    {
        "json": {"foo::date": "08/20/2007"},
        "purpose": "Date parsing: 08/20/2007"
    },
    {
        "json": {"foo::date": "08/20/07"},
        "purpose": "Date parsing: 08/20/07"
    },
    {
        "json": {"foo::date": "20070920"},
        "purpose": "Date parsing: 20070920"
    },
    {
        "json": {"foo::date": "December 20th, 2005"},
        "purpose": "Date parsing: December 20th, 2005"
    }
];

$(document).ready(function() {
    corona.fetchInfo(function(info) {
        console.log(info);
        if(info.features.JSONDocs === false) {
            ok(true, "No support for JSON with this version of MarkLogic");
            return;
        }

        module("Bad JSON");
        for (var i = 0; i < corona.badJSON.length; i += 1) {
            corona.badFromServerTest(corona.badJSON[i]);
        }

        module("Good JSON");
        for (var i = 0; i < corona.validJSON.length; i += 1) {
            corona.jsonFromServerTest(corona.validJSON[i]);
        }

        module("JSON Construction");
        asyncTest("Array construction", function() {
            $.ajax({
                url: "/test/xq/array-construction.xqy",
                success: function(data) {
                    ok(true, "Array construction success");
                    deepEqual(JSON.parse(data), [1,1.2,true,false,null,[],{"foo":"bar"}], "Constructed array comparison");
                },
                error: function() {
                    ok(false, "Array construction");
                },
                complete: function() { start(); }
            });
        });
        asyncTest("Object construction", function() {
            $.ajax({
                url: "/test/xq/object-construction.xqy",
                success: function(data) {
                    ok(true, "Object construction success");
                    deepEqual(JSON.parse(data), {"intvalue":1,"floatvalue":1.2,"boolvalue":true,"nullvalue":null,"arrayvalue":[1,2,3],"objectvalue":{"foo":"bar"},"datevalue::date":"July 8th, 2011","xmlvalue::xml":"<foo><bar/></foo>","notrailingvalue":null}, "Constructed object comparison");
                },
                error: function() {
                    ok(false, "Object construction");
                },
                complete: function() { start(); }
            });
        });
        asyncTest("Object construction duplicate key should fail", function() {
            $.ajax({
                url: "/test/xq/object-construction-dup-keys.xqy",
                success: function() {
                    ok(false, "Object construction duplicate key should fail");
                },
                error: function() {
                    ok(true, "Object construction duplicate key should fail");
                },
                complete: function() { start(); }
            });
        });
    });
});


corona.jsonFromServer = function(test, success, error) {
    var jsonString = test.jsonString;
    if(jsonString === undefined) {
        jsonString = JSON.stringify(test.json)
    }
    asyncTest(test.purpose, function() {
        $.ajax({
            url: '/test/xq/isomorphic.xqy',
            data: {"json": jsonString},
            method: 'POST',
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

corona.badFromServerTest = function(test) {
    corona.jsonFromServer(test,
        function(data, t, j) {
            equals(data, test.error, test.purpose);
        },
        function(j, t, error) {
            equals(error, test.error, test.purpose);
        }
    );
};

corona.jsonFromServerTest = function(test) {
    corona.jsonFromServer(test,
        function(data, t, j) {
            deepEqual(JSON.parse(data), test.json, test.purpose);
        },
        function(j, t, e) { ok(false, e); console.log(e); } 
    );
};
