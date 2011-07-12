(:
Copyright 2011 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

xquery version "1.0-ml";

import module namespace manage="http://marklogic.com/mljson/manage" at "lib/manage.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace jsonquery="http://marklogic.com/json-query" at "lib/json-query.xqy";
import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";

declare option xdmp:mapping "false";

json:xmlToJSON(json:object(
    let $facets := tokenize(xdmp:get-request-field("facets")[1], ",")
    let $query := xdmp:get-request-field("q")[1]
    let $customQuery := xdmp:get-request-field("customquery")[1]

    let $start := xs:integer(xdmp:get-request-field("__MLJSONURL__:start", "1"))
    let $end := xs:integer(xdmp:get-request-field("__MLJSONURL__:end", "25"))

    let $query :=
        if(exists($query))
        then parser:parse($query)
        else if(exists($customQuery))
        then jsonquery:getCTS($customQuery)
        else ()

    for $facet in $facets
    let $indexDef := manage:getRange($facet)
    where exists($indexDef)
    return (
        $facet, json:array(json:rangeIndexValues($indexDef, $query, (), $start, $end))
    )
))
