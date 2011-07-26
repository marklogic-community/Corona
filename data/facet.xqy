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
import module namespace customquery="http://marklogic.com/mljson/custom-query" at "lib/custom-query.xqy";
import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";

declare option xdmp:mapping "false";

json:xmlToJSON(json:object(
    let $facets := tokenize(xdmp:get-request-field("facets")[1], ",")
    let $queryString := xdmp:get-request-field("q")[1]
    let $customQuery := xdmp:get-request-field("customquery")[1]

    let $limit := xs:integer(xdmp:get-request-field("limit", "25"))
    let $order := xdmp:get-request-field("order")[1]
    let $frequency := xdmp:get-request-field("frequency")[1]

    let $query :=
        if(exists($queryString))
        then parser:parse($queryString)
        else if(exists($customQuery))
        then customquery:getCTS($customQuery)
        else ()

    let $options := (
        if($order = "frequency")
        then "frequency-order"
        else $order,
        if($frequency = "document")
        then "fragment-frequency"
        else "item-frequency"
    )

    for $facet in $facets
    let $indexDef := manage:getRange($facet)
    where exists($indexDef)
    return (
        $facet, json:array(
            for $item in json:rangeIndexValues($indexDef, $query, $options, $limit)
            return json:object((
                "value", $item,
                "count", cts:frequency($item)
            ))
        )
    )
))
