if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.wordQueryValue = function(word) {
    return '<cts:element-word-query weight="10"> <cts:element xmlns:json="http://marklogic.com/json">json:subject</cts:element> <cts:text xml:lang="en">' + word + '</cts:text> </cts:element-word-query> <cts:element-word-query weight="8"> <cts:element xmlns:testns="http://test.ns/uri">testns:subject</cts:element> <cts:text xml:lang="en">' + word + '</cts:text> </cts:element-word-query> <cts:element-attribute-word-query weight="8"> <cts:element xmlns:testns="http://test.ns/uri">testns:subject</cts:element> <cts:attribute>normalized</cts:attribute> <cts:text xml:lang="en">' + word + '</cts:text> </cts:element-attribute-word-query> <cts:element-word-query weight="10"> <cts:element xmlns:json="http://marklogic.com/json">json:tri_003Dck_007Cey</cts:element> <cts:text xml:lang="en">' + word + '</cts:text> </cts:element-word-query>';
};

corona.queries = [
    {
        "query": 'foo',
        "result": '<cts:or-query xmlns:cts="http://marklogic.com/cts"> ' + corona.wordQueryValue("foo") + '</cts:or-query>',
        "purpose": "Simple word query"
    },
    {
        "query": '"foo bar"',
        "result": '<cts:or-query xmlns:cts="http://marklogic.com/cts"> ' + corona.wordQueryValue("foo bar") + '</cts:or-query>',
        "purpose": "Simple phrase query"
    },
    {
        "query": 'foo bar',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:or-query> ' + corona.wordQueryValue("foo") + ' </cts:or-query> <cts:or-query> ' + corona.wordQueryValue("bar") + ' </cts:or-query></cts:and-query>',
        "purpose": "Implicit AND query"
    },
    {
        "query": 'foo AND bar',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:or-query> ' + corona.wordQueryValue("foo") + ' </cts:or-query> <cts:or-query> ' + corona.wordQueryValue("bar") + ' </cts:or-query></cts:and-query>',
        "purpose": "Explicit AND query"
    },
    {
        "query": 'foo OR bar',
        "result": '<cts:or-query xmlns:cts="http://marklogic.com/cts"> ' + corona.wordQueryValue("foo") + ' ' + corona.wordQueryValue("bar") + '</cts:or-query>',
        "purpose": "Explicit OR query"
    },
    {
        "query": 'foo NEAR bar',
        "result": '<cts:near-query distance="10" xmlns:cts="http://marklogic.com/cts"> <cts:and-query> <cts:or-query> ' + corona.wordQueryValue("foo") + ' </cts:or-query> <cts:or-query> ' + corona.wordQueryValue("bar") + ' </cts:or-query> </cts:and-query></cts:near-query>',
        "purpose": "Explicit NEAR query"
    },
    {
        "query": 'foo NEAR/5 bar',
        "result": '<cts:near-query distance="5" xmlns:cts="http://marklogic.com/cts"> <cts:and-query> <cts:or-query> ' + corona.wordQueryValue("foo") + ' </cts:or-query> <cts:or-query> ' + corona.wordQueryValue("bar") + ' </cts:or-query> </cts:and-query></cts:near-query>',
        "purpose": "Explicit NEAR query with distance"
    },
    {
        "query": 'foo (bar OR baz)',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:or-query> ' + corona.wordQueryValue("foo") + ' </cts:or-query> <cts:or-query> ' + corona.wordQueryValue("bar") + ' ' + corona.wordQueryValue("baz") + ' </cts:or-query></cts:and-query>',
        "purpose": "Grouping"
    },
    {
        "query": 'place1:foo',
        "result": '<cts:field-word-query xmlns:cts="http://marklogic.com/cts"> <cts:field>corona-field-place1</cts:field> <cts:text xml:lang="en">foo</cts:text></cts:field-word-query>',
        "purpose": "Place constraint"
    },
    {
        "query": 'place1:foo OR place1:bar',
        "result": '<cts:or-query xmlns:cts="http://marklogic.com/cts"> <cts:field-word-query> <cts:field>corona-field-place1</cts:field> <cts:text xml:lang="en">foo</cts:text> </cts:field-word-query> <cts:field-word-query> <cts:field>corona-field-place1</cts:field> <cts:text xml:lang="en">bar</cts:text> </cts:field-word-query></cts:or-query>',
        "purpose": "Place constraint or'd with another place constraint"
    },
    {
        "query": 'range1:2007-01-25',
        "result": '<cts:element-attribute-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2007-01-25T00:00:00-07:00</cts:value></cts:element-attribute-range-query>',
        "purpose": "Date range constraint"
    },
    {
        "query": 'range1-after:2007-01-25',
        "result": '<cts:element-attribute-range-query operator="&gt;=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2007-01-25T00:00:00-07:00</cts:value></cts:element-attribute-range-query>',
        "purpose": "Date after range constraint"
    },
    {
        "query": 'range1-before:2007-01-25',
        "result": '<cts:element-attribute-range-query operator="&lt;=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2007-01-25T00:00:00-07:00</cts:value></cts:element-attribute-range-query>',
        "purpose": "Date before range constraint"
    },
    {
        "query": 'range2:foo',
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:rangeKey</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "String range constraint"
    },
    {
        "query": 'range3:10',
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:rangeKey</cts:element> <cts:value xsi:type="xs:decimal" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10</cts:value></cts:element-range-query>',
        "purpose": "Number range constraint"
    },
    {
        "query": 'range4:foo',
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element>rangeKey</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "XML element range constraint"
    },
    {
        "query": 'range5:foo',
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:rangeEl</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "Namespaced XML element range constraint"
    },
    {
        "query": 'range6:foo',
        "result": '<cts:element-attribute-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:rangeEl</cts:element> <cts:attribute>rangeAttrib</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-attribute-range-query>',
        "purpose": "Namespaced XML attribute range constraint"
    },
    {
        "query": 'fromBucket:G-M',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-range-query operator="&gt;="> <cts:element xmlns:json="http://marklogic.com/json">json:fromPersonal</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">G</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-range-query> <cts:element-range-query operator="&lt;"> <cts:element xmlns:json="http://marklogic.com/json">json:fromPersonal</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">N</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-range-query></cts:and-query>',
        "purpose": "Explicitly defined bucket constraint"
    },
    {
        "query": 'fromBucketXML:G-M',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-attribute-range-query operator="&gt;="> <cts:element>from</cts:element> <cts:attribute>personal</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">G</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-attribute-range-query> <cts:element-attribute-range-query operator="&lt;"> <cts:element>from</cts:element> <cts:attribute>personal</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">N</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-attribute-range-query></cts:and-query>',
        "purpose": "Explicitly defined bucket attribute constraint"
    },
    {
        "query": 'messageDate:"Sep 01 2010 - Oct 01 2010"',
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-attribute-range-query operator="&gt;="> <cts:element xmlns:json="http://marklogic.com/json">json:date_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2010-09-01T00:00:00</cts:value> </cts:element-attribute-range-query> <cts:element-attribute-range-query operator="&lt;"> <cts:element xmlns:json="http://marklogic.com/json">json:date_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2010-10-01T00:00:00</cts:value> </cts:element-attribute-range-query></cts:and-query>',
        "purpose": "Explicitly defined bucket attribute constraint"
    },
    {
        "query": 'geokey:37.819722, -122.478611',
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongKey</cts:element> <cts:region xsi:type="cts:circle" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">@10 37.819721,-122.47861</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Unquoted gespatial query"
    },
    {
        "query": 'geokey:-37.819722, -122.478611',
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongKey</cts:element> <cts:region xsi:type="cts:circle" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">@10 -37.819721,-122.47861</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Negative first gespatial query"
    },
    {
        "query": 'geokey:"37.819722, -122.478611"',
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongKey</cts:element> <cts:region xsi:type="cts:circle" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">@10 37.819721,-122.47861</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Quoted gespatial query"
    },
    {
        "query": 'zip:94402',
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongKey</cts:element> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">37.554167,-122.31306</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Stored query"
    }
];

$(document).ready(function() {
    module("String Queries");
    for (var i = 0; i < corona.queries.length; i += 1) {
        corona.queryFromServerTest(corona.queries[i]);
    }
});


corona.queryFromServer = function(test, success, error) {
    asyncTest(test.purpose, function() {
        $.ajax({
            url: '/test/xq/parse-string-query.xqy',
            data: {"stringQuery": test.query},
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

corona.queryFromServerTest = function(test) {
    corona.queryFromServer(test,
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
