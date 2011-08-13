if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.queries = [
    /* Contains */
    {
        "query": { "contains": {
                "key": "foo",
                "string": "bar"
            }
        },
        "result": '<cts:element-word-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-word-query>',
        "purpose": "Simple JSON contains query"
    },
    {
        "query": { "contains": {
                "element": "foo",
                "string": "bar"
            }
        },
        "result": '<cts:element-word-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-word-query>',
        "purpose": "Simple XML element contains query"
    },
    {
        "query": { "contains": {
                "element": "testns:foo",
                "string": "bar"
            }
        },
        "result": '<cts:element-word-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-word-query>',
        "purpose": "Simple XML namespaced element contains query"
    },
    {
        "query": { "contains": {
                "element": "foo",
                "attribute": "bar",
                "string": "baz"
            }
        },
        "result": '<cts:element-attribute-word-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:attribute>bar</cts:attribute> <cts:text xml:lang="en">baz</cts:text></cts:element-attribute-word-query>',
        "purpose": "Simple XML namespaced element/attribute contains query"
    },
    {
        "query": { "contains": {
                "key": "foo",
                "string": "bar",
                "caseSensitive": true,
                "diacriticSensitive": true,
                "punctuationSensitve": true,
                "whitespaceSensitive": true,
                "stemmed": false,
                "wildcarded": true,
                "weight": 10
            }
        },
        "result": '<cts:element-word-query weight="10" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> <cts:option>case-sensitive</cts:option> <cts:option>diacritic-sensitive</cts:option> <cts:option>punctuation-sensitive</cts:option> <cts:option>whitespace-sensitive</cts:option> <cts:option>unstemmed</cts:option> <cts:option>wildcarded</cts:option></cts:element-word-query>',
        "purpose": "Extract word options"
    },
    {
        "query": { "contains": {
                "key": "foo",
                "string": ["bar", "baz"]
            }
        },
        "result": '<cts:element-word-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> <cts:text xml:lang="en">baz</cts:text></cts:element-word-query>',
        "purpose": "Value as an array"
    },

    /* Equals */
    {
        "query": { "equals": {
                "key": "foo",
                "value": "bar"
            }
        },
        "result": '<cts:element-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-value-query>',
        "purpose": "Simple JSON equals query (string)"
    },
    {
        "query": { "equals": {
                "key": "foo",
                "value": true
            }
        },
        "result": '<cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:attribute>boolean</cts:attribute> <cts:text xml:lang="en">true</cts:text></cts:element-attribute-value-query>',
        "purpose": "Simple JSON equals query (boolean)"
    },
    {
        "query": { "equals": {
                "key": "foo",
                "value": 10
            }
        },
        "result": '<cts:element-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">10</cts:text></cts:element-value-query>',
        "purpose": "Simple JSON equals query (number)"
    },
    {
        "query": { "equals": {
                "key": "foo::date",
                "value": "November 10th, 1980"
            }
        },
        "result": '<cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:text xml:lang="en">1980-11-10T00:00:00-07:00</cts:text></cts:element-attribute-value-query>',
        "purpose": "Simple JSON equals query (date)"
    },
    {
        "query": { "equals": {
                "element": "foo",
                "value": "bar"
            }
        },
        "result": '<cts:element-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-value-query>',
        "purpose": "Simple XML element equals query"
    },
    {
        "query": { "equals": {
                "element": "testns:foo",
                "value": "bar"
            }
        },
        "result": '<cts:element-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:foo</cts:element> <cts:text xml:lang="en">bar</cts:text></cts:element-value-query>',
        "purpose": "Simple XML namespaced element equals query"
    },
    {
        "query": { "equals": {
                "element": "foo",
                "attribute": "bar",
                "value": "baz"
            }
        },
        "result": '<cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:attribute>bar</cts:attribute> <cts:text xml:lang="en">baz</cts:text></cts:element-attribute-value-query>',
        "purpose": "Simple XML attribute equals query"
    },

    /* And */
    {
        "query": { "and": [
            { "equals": {
                "key": "foo",
                "value": "bar"
            }},
            { "equals": {
                "key": "foo",
                "value": "baz"
            }}
        ]},
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">baz</cts:text> </cts:element-value-query></cts:and-query>',
        "purpose": "And query"
    },

    /* Or */
    {
        "query": { "or": [
            { "equals": {
                "key": "foo",
                "value": "bar"
            }},
            { "equals": {
                "key": "foo",
                "value": "baz"
            }}
        ]},
        "result": '<cts:or-query xmlns:cts="http://marklogic.com/cts"> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">baz</cts:text> </cts:element-value-query></cts:or-query>',
        "purpose": "Or query"
    },

    /* Not */
    {
        "query": { "not": 
            { "equals": {
                "key": "foo",
                "value": "bar"
            }}
        },
        "result": '<cts:not-query xmlns:cts="http://marklogic.com/cts"> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query></cts:not-query>',
        "purpose": "Not query"
    },

    /* And Not */
    {
        "query": { "andNot": {
            "positive": { "equals": {
                "key": "foo",
                "value": "bar"
            }},
            "negative": { "equals": {
                "key": "foo",
                "value": "baz"
            }}
        }},
        "result": '<cts:and-not-query xmlns:cts="http://marklogic.com/cts"> <cts:positive> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query> </cts:positive> <cts:negative> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">baz</cts:text> </cts:element-value-query> </cts:negative></cts:and-not-query>',
        "purpose": "And not query"
    },

    /* Near */
    {
        "query": { "near": {
            "queries": [
                { "equals": {
                    "key": "foo",
                    "value": "bar"
                }},
                { "equals": {
                    "key": "foo",
                    "value": "baz"
                }}
            ],
            "ordered": true,
            "distance": 15,
            "weight": 2
        }},
        "result": '<cts:near-query weight="2" distance="15" xmlns:cts="http://marklogic.com/cts"> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">baz</cts:text> </cts:element-value-query> <cts:option>ordered</cts:option></cts:near-query>',
        "purpose": "Near query"
    },

    /* isNULL */
    {
        "query": { "isNULL": {
            "key": "foo"
        }},
        "result": '<cts:element-attribute-value-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:attribute>type</cts:attribute> <cts:text xml:lang="en">null</cts:text></cts:element-attribute-value-query>',
        "purpose": "isNULL query"
    },

    /* keyExists */
    {
        "query": { "keyExists": {
            "key": "foo"
        }},
        "result": '<cts:element-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:and-query/></cts:element-query>',
        "purpose": "keyExists query"
    },

    /* Collection */
    {
        "query": { "collection": "foo" },
        "result": '<cts:collection-query xmlns:cts="http://marklogic.com/cts"> <cts:uri>foo</cts:uri></cts:collection-query>',
        "purpose": "Collection query"
    },
    {
        "query": { "collection": ["foo", "bar"] },
        "result": '<cts:collection-query xmlns:cts="http://marklogic.com/cts"> <cts:uri>foo</cts:uri> <cts:uri>bar</cts:uri></cts:collection-query>',
        "purpose": "Collection query with an array of values"
    },

    /* Directory */
    {
        "query": { "directory": "/foo" },
        "result": '<cts:directory-query xmlns:cts="http://marklogic.com/cts"> <cts:uri>/foo</cts:uri></cts:directory-query>',
        "purpose": "Directory query"
    },
    {
        "query": { "directory": {"uri": "/foo", "descendants": true}},
        "result": '<cts:directory-query depth="infinity" xmlns:cts="http://marklogic.com/cts"> <cts:uri>/foo</cts:uri></cts:directory-query>',
        "purpose": "Directory query with a depth"
    },

    /* Properties */
    {
        "query": { "property": { "equals": {
                "key": "foo",
                "value": "bar"
            }}
        },
        "result": '<cts:properties-query xmlns:cts="http://marklogic.com/cts"> <cts:element-value-query> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:text xml:lang="en">bar</cts:text> </cts:element-value-query></cts:properties-query>',
        "purpose": "Property query"
    },

    /* Range */
    {
        "query": { "range": {
            "name": "range1",
            "value": "November 17th 1980"
        }},
        "result": '<cts:element-attribute-range-query operator="&gt;" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">1980-11-17T00:00:00-07:00</cts:value></cts:element-attribute-range-query>',
        "purpose": "JSON date range query"
    },
    {
        "query": { "range": {
            "name": "range1",
            "from": "November 17th 1980",
            "to": "November 17th 1981"
        }},
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-attribute-range-query operator="&gt;="> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">1980-11-17T00:00:00-07:00</cts:value> </cts:element-attribute-range-query> <cts:element-attribute-range-query operator="&lt;="> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">1981-11-17T00:00:00-07:00</cts:value> </cts:element-attribute-range-query></cts:and-query>',
        "purpose": "JSON date range query with from and to"
    },
    {
        "query": { "range": {
            "name": "range2",
            "value": "foo"
        }},
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:rangeKey</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "JSON string range query"
    },
    {
        "query": { "range": {
            "name": "range4",
            "value": "foo"
        }},
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element>rangeKey</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "XML element string range query"
    },
    {
        "query": { "range": {
            "name": "range5",
            "value": "foo"
        }},
        "result": '<cts:element-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:rangeEl</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-range-query>',
        "purpose": "XML namespaced element string range query"
    },
    {
        "query": { "range": {
            "name": "range6",
            "value": "foo"
        }},
        "result": '<cts:element-attribute-range-query operator="=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:testns="http://test.ns/uri">testns:rangeEl</cts:element> <cts:attribute>rangeAttrib</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">foo</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option></cts:element-attribute-range-query>',
        "purpose": "XML namespaced element attribute string range query"
    },
    {
        "query": { "range": {
            "name": "range1",
            "value": "November 17th 1980",
            "operator": "ne"
        }},
        "result": '<cts:element-attribute-range-query operator="!=" xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:date1_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">1980-11-17T00:00:00-07:00</cts:value></cts:element-attribute-range-query>',
        "purpose": "Range query operator override"
    },
    {
        "query": { "range": {
            "name": "fromBucket",
            "bucketLabel": "G-M",
        }},
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-range-query operator="&gt;="> <cts:element xmlns:json="http://marklogic.com/json">json:fromPersonal</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">G</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-range-query> <cts:element-range-query operator="&lt;"> <cts:element xmlns:json="http://marklogic.com/json">json:fromPersonal</cts:element> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">N</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-range-query></cts:and-query>',
        "purpose": "JSON bucketed range label query"
    },
    {
        "query": { "range": {
            "name": "fromBucketXML",
            "bucketLabel": "G-M",
        }},
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-attribute-range-query operator="&gt;="> <cts:element>from</cts:element> <cts:attribute>personal</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">G</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-attribute-range-query> <cts:element-attribute-range-query operator="&lt;"> <cts:element>from</cts:element> <cts:attribute>personal</cts:attribute> <cts:value xsi:type="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">N</cts:value> <cts:option>collation=http://marklogic.com/collation/</cts:option> </cts:element-attribute-range-query></cts:and-query>',
        "purpose": "XML bucketed range label query"
    },
    {
        "query": { "range": {
            "name": "messageDate",
            "bucketLabel": "Sep 01 2010 - Oct 01 2010",
        }},
        "result": '<cts:and-query xmlns:cts="http://marklogic.com/cts"> <cts:element-attribute-range-query operator="&gt;="> <cts:element xmlns:json="http://marklogic.com/json">json:date_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2010-09-01T00:00:00</cts:value> </cts:element-attribute-range-query> <cts:element-attribute-range-query operator="&lt;"> <cts:element xmlns:json="http://marklogic.com/json">json:date_003A_003Adate</cts:element> <cts:attribute>normalized-date</cts:attribute> <cts:value xsi:type="xs:dateTime" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2010-10-01T00:00:00</cts:value> </cts:element-attribute-range-query></cts:and-query>',
        "purpose": "JSON auto bucketed range label query"
    },
    {
        "query": { "range": {
            "name": "messageDate",
            "bucketLabel": "Sep 01 2010 - Oct 01 2010",
        }},
        "ignoreRange": "messageDate",
        "result": '',
        "purpose": "Ignore range paramater"
    },

    /* Geo */
    {
        "query": { "geo": {
            "key": "latLongPair",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongPair</cts:element> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Geo query with JSON key"
    },
    {
        "query": { "geo": {
            "element": "latLongPair",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element>latLongPair</cts:element> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Geo query with XML element"
    },
    {
        "query": { "geo": {
            "parentKey": "foo",
            "key": "latLongPair",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-child-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:child xmlns:json="http://marklogic.com/json">json:latLongPair</cts:child> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-child-geospatial-query>',
        "purpose": "Geo query with parent and child JSON keys"
    },
    {
        "query": { "geo": {
            "parentElement": "foo",
            "element": "latLongPair",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-child-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:child>latLongPair</cts:child> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-child-geospatial-query>',
        "purpose": "Geo query with parent and child XML elements"
    },
    {
        "query": { "geo": {
            "parentKey": "foo",
            "latKey": "lat",
            "longKey": "long",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-pair-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:foo</cts:element> <cts:latitude xmlns:json="http://marklogic.com/json">json:lat</cts:latitude> <cts:longitude xmlns:json="http://marklogic.com/json">json:long</cts:longitude> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-pair-geospatial-query>',
        "purpose": "Geo query with parent, lat and long JSON keys"
    },
    {
        "query": { "geo": {
            "parentElement": "foo",
            "latElement": "lat",
            "longElement": "long",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-pair-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:latitude>lat</cts:latitude> <cts:longitude>long</cts:longitude> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-pair-geospatial-query>',
        "purpose": "Geo query with parent, lat and long XML elements"
    },
    {
        "query": { "geo": {
            "parentElement": "foo",
            "latAttribute": "lat",
            "longAttribute": "long",
            "region": {
                "point": {
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-attribute-pair-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element>foo</cts:element> <cts:latitude>lat</cts:latitude> <cts:longitude>long</cts:longitude> <cts:region xsi:type="cts:point" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-attribute-pair-geospatial-query>',
        "purpose": "Geo query with parent, lat and long XML elements"
    },

    {
        "query": { "geo": {
            "key": "latLongPair",
            "region": {
                "circle": {
                    "radius": 15,
                    "latitude": 10,
                    "longitude": -10
                }
            }
        }},
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongPair</cts:element> <cts:region xsi:type="cts:circle" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">@15 10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Geo circle construction"
    },
    {
        "query": { "geo": {
            "key": "latLongPair",
            "region": {
                "box": {
                    "north": 1,
                    "south": -1,
                    "east": 2,
                    "west": -2 
                }
            }
        }},
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongPair</cts:element> <cts:region xsi:type="cts:box" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">[-1, -2, 1, 2]</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Geo box construction"
    },
    {
        "query": { "geo": {
            "key": "latLongPair",
            "region": {
                "polygon": [
                    {
                        "latitude": 10,
                        "longitude": -10
                    },
                    {
                        "latitude": 11,
                        "longitude": -9
                    },
                    {
                        "latitude": 12,
                        "longitude": -8
                    }
                ]
            }
        }},
        "result": '<cts:element-geospatial-query xmlns:cts="http://marklogic.com/cts"> <cts:element xmlns:json="http://marklogic.com/json">json:latLongPair</cts:element> <cts:region xsi:type="cts:polygon" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">10,-10 11,-9 12,-8 10,-10</cts:region> <cts:option>coordinate-system=wgs84</cts:option></cts:element-geospatial-query>',
        "purpose": "Geo polygon construction"
    },
];

$(document).ready(function() {
    module("Custom Queries");
    for (var i = 0; i < mljson.queries.length; i += 1) {
        mljson.queryFromServerTest(mljson.queries[i]);
    }
});


mljson.queryFromServer = function(test, success, error) {
    asyncTest(test.purpose, function() {
        var data = {"q": JSON.stringify(test.query)}
        if(test.ignoreRange !== undefined) {
            data.ignoreRange = test.ignoreRange;
        }
        $.ajax({
            url: '/test/xq/parsecustomquery.xqy',
            data: data,
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

mljson.queryFromServerTest = function(test) {
    mljson.queryFromServer(test,
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
