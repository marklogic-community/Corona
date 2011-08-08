if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.paths = [
    {
        "path": 'foo.bar.baz[1]',
        "result": "json:foo/json:bar/json:baz/json:item[1]",
        "purpose": "Simple steps with array access at end"
    },
    {
        "path": '["foo"]["bar"]["baz"][1]',
        "result": "json:foo/json:bar/json:baz/json:item[1]",
        "purpose": "Quoted steps with array access at end"
    },
    {
        "path": 'root().foo.bar',
        "result": "ancestor-or-self::json:json/json:foo/json:bar",
        "purpose": "root() function"
    },
    {
        "path": 'foo.bar.baz.parent()',
        "result": "json:foo/json:bar/json:baz/..",
        "purpose": "parent() function"
    },
    {
        "path": 'foo.bar.baz.ancestor("foo")',
        "result": "json:foo/json:bar/json:baz/ancestor::json:foo",
        "purpose": "ancestor() function"
    },
    {
        "path": 'foo.*.bar',
        "result": "json:foo//json:bar",
        "purpose": "Wildstep between simple steps"
    },
    {
        "path": '*.foo.bar',
        "result": "//json:foo/json:bar",
        "purpose": "Wildstep as first steps"
    },
    {
        "path": 'foo.bar.*',
        "result": "json:foo/json:bar/*",
        "purpose": "Wildstep as last steps"
    },
    {
        "path": 'foo.bar.xpath("baz/yaz")',
        "result": "json:foo/json:bar/baz/yaz",
        "purpose": "XPath function"
    },
    {
        "path": 'foo..bar',
        "error": "Unexpected token '.' in path 'foo..bar', expected either a step or a function call.",
        "purpose": "Double dots"
    },
    {
        "path": 'foo*',
        "error": "Unexpected token '*' in path 'foo*', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot between simple step and wildstep"
    },
    {
        "path": 'foo.**',
        "error": "Unexpected token '*' in path 'foo.**', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot between wild steps"
    },
    {
        "path": 'foo.parent()bar',
        "error": "Unexpected token 'bar' in path 'foo.parent()bar', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot after parent() function"
    },
    {
        "path": 'foo.ancestor("baz")bar',
        "error": "Unexpected token 'bar' in path 'foo.ancestor(\"baz\")bar', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot after ancestor() function"
    }
];

$(document).ready(function() {
    module("Paths");
    for (var i = 0; i < mljson.paths.length; i += 1) {
        mljson.pathFromServerTest(mljson.paths[i]);
    }
});


mljson.pathFromServer = function(test, success, error) {
    asyncTest(test.purpose, function() {
        $.ajax({
            url: '/test/xq/parsepath.xqy',
            data: {"path": test.path},
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

mljson.pathFromServerTest = function(test) {
    mljson.pathFromServer(test,
        function(data, t, j) {
            if(test.error !== undefined) {
                equals(data, test.error, test.purpose);
            }
            else if(test.result !== undefined) {
                equals(data, test.result, test.purpose);
            }
        },
        function(j, t, e) { ok(false, e); console.log(e); } 
    );
};
