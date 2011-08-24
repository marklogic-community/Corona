if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.paths = [
    {
        "path": 'foo.bar.baz[0]',
        "type": "json",
        "result": "json:foo/json:bar/json:baz/json:item[1]",
        "purpose": "Simple steps with array access at end"
    },
    {
        "path": '["foo"]["bar"]["baz"][0]',
        "type": "json",
        "result": "json:foo/json:bar/json:baz/json:item[1]",
        "purpose": "Quoted steps with array access at end"
    },
    {
        "path": 'root().foo.bar',
        "type": "json",
        "result": "ancestor-or-self::json:json/json:foo/json:bar",
        "purpose": "root() function"
    },
    {
        "path": 'foo.bar.baz.parent()',
        "type": "json",
        "result": "json:foo/json:bar/json:baz/..",
        "purpose": "parent() function"
    },
    {
        "path": 'foo.bar.baz.ancestor("foo")',
        "type": "json",
        "result": "json:foo/json:bar/json:baz/ancestor::json:foo",
        "purpose": "ancestor() function"
    },
    {
        "path": 'foo.*.bar',
        "type": "json",
        "result": "json:foo//json:bar",
        "purpose": "Wildstep between simple steps"
    },
    {
        "path": '*.foo.bar',
        "type": "json",
        "result": "//json:foo/json:bar",
        "purpose": "Wildstep as first steps"
    },
    {
        "path": 'foo.bar.*',
        "type": "json",
        "result": "json:foo/json:bar/*",
        "purpose": "Wildstep as last steps"
    },
    {
        "path": 'foo.bar.xpath("baz/yaz")',
        "type": "json",
        "result": "json:foo/json:bar/baz/yaz",
        "purpose": "XPath function"
    },
    {
        "path": 'foo..bar',
        "type": "json",
        "error": "Unexpected token '.' in path 'foo..bar', expected either a step or a function call.",
        "purpose": "Double dots"
    },
    {
        "path": 'foo*',
        "type": "json",
        "error": "Unexpected token '*' in path 'foo*', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot between simple step and wildstep"
    },
    {
        "path": 'foo.**',
        "type": "json",
        "error": "Unexpected token '*' in path 'foo.**', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot between wild steps"
    },
    {
        "path": 'foo.parent()bar',
        "type": "json",
        "error": "Unexpected token 'bar' in path 'foo.parent()bar', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot after parent() function"
    },
    {
        "path": 'foo.ancestor("baz")bar',
        "type": "json",
        "error": "Unexpected token 'bar' in path 'foo.ancestor(\"baz\")bar', expected either a dot, a quoted step or an array index.",
        "purpose": "Missing dot after ancestor() function"
    },

    {
        "path": 'foo/bar/ancestor::foo/ancestor-or-self::bar/child::foo/descendant::bar//foo/descendant-or-self::bar/following::foo/following-sibling::bar/parent::foo/../preceding::bar/preceding-sibling::foo/self::bar/*/foo[30]/bar/@foo',
        "type": "xml",
        "purpose": "XPath that hits all the touch points"
    },

    {
        "path": 'foo//',
        "type": "xml",
        "error": "Unexpected token '/' in path 'foo//', expected either an XML element or an XPath axis.",
        "purpose": "Trailing double slash"
    },
    {
        "path": 'foo/[1]',
        "type": "xml",
        "error": "Unexpected token '[1]' in path 'foo/[1]', expected either an XML element or an XPath axis.",
        "purpose": "Missing element name before predicate"
    },
    {
        "path": 'ancestor::foodescendant::bar',
        "type": "xml",
        "error": "Invalid XML element name or undefined namespace prefix: 'foodescendant::bar'.",
        "purpose": "Bogus element name"
    },
    {
        "path": 'foo/@',
        "type": "xml",
        "error": "Unexpected token '@' in path 'foo/@'",
        "purpose": "Bogus element name"
    },
    {
        "path": 'foo/@bar/baz',
        "type": "xml",
        "error": "Unexpected token '/' in path 'foo/@bar/baz', cannot descend into attribute values.",
        "purpose": "Bogus element name"
    },
    {
        "path": 'foo[1][2]',
        "type": "xml",
        "error": "Unexpected token '[2]' in path 'foo[1][2]', expected a slash.",
        "purpose": "Smashed up predicates"
    },
    {
        "path": 'foo[1]/[2]',
        "type": "xml",
        "error": "Unexpected token '[2]' in path 'foo[1]/[2]', expected either an XML element or an XPath axis.",
        "purpose": "Missing element name before predicate"
    },
    {
        "path": 'foo///bar',
        "type": "xml",
        "error": "Unexpected token '/' in path 'foo////bar', expected either an XML element or an XPath axis.",
        "purpose": "Tripple slash"
    },
    {
        "path": 'foo/**/bar',
        "type": "xml",
        "error": "Unexpected token '*' in path 'foo/**/bar', expected either a slash or a predicate.",
        "purpose": "Double wild"
    }
];

$(document).ready(function() {
    module("Paths");
    for (var i = 0; i < corona.paths.length; i += 1) {
        corona.pathFromServerTest(corona.paths[i]);
    }
});


corona.pathFromServer = function(test, success, error) {
    asyncTest(test.purpose, function() {
        $.ajax({
            url: '/test/xq/parsepath.xqy',
            data: {"path": test.path, "type": test.type},
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

corona.pathFromServerTest = function(test) {
    corona.pathFromServer(test,
        function(data, t, j) {
            if(test.error !== undefined) {
                equals(data, test.error, test.purpose);
            }
            else if(test.result !== undefined) {
                equals(data, test.result, test.purpose);
            }
            else if(test.type === "xml") {
                equals(data, test.path, test.purpose);
            }
        },
        function(j, t, e) { ok(false, e); console.log(e); } 
    );
};
