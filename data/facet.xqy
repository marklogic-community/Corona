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

import module namespace config="http://marklogic.com/mljson/index-config" at "lib/index-config.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace customquery="http://marklogic.com/mljson/custom-query" at "lib/custom-query.xqy";
import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";

declare option xdmp:mapping "false";

let $facets := tokenize(xdmp:get-request-field("facets")[1], ",")
let $contentType := xdmp:get-request-field("content-type")[1]
let $queryString := xdmp:get-request-field("q")[1]
let $customQuery := xdmp:get-request-field("customquery")[1]

let $limit := xs:integer(xdmp:get-request-field("limit", "25"))
let $order := xdmp:get-request-field("order")[1]
let $frequency := xdmp:get-request-field("frequency")[1]

let $query :=
    if(exists($queryString))
    then parser:parse($queryString)
    else if(exists($customQuery))
    then customquery:getCTS($customQuery, ())
    else ()

let $options := (
    if($order = "frequency")
    then "frequency-order"
    else $order,
    if($frequency = "document")
    then "fragment-frequency"
    else "item-frequency"
)

let $values :=
    for $facet in $facets
    let $index := config:get($facet)
    let $values :=
        if($index/structure = "json")
        then json:rangeIndexValues(json:unescapeNCName($index/key), $index/type, $query, $options, $limit)
        else if($index/structure = "xmlelement")
        then cts:element-values(xs:QName($index/element), (), (concat("type=", $index/type), $options), $query)
        else if($index/structure = "xmlattribute")
        then cts:element-attribute-values(xs:QName($index/element), xs:QName($index/attribute), (), (concat("type=", $index/type), $options), $query)
        else ()

    where exists($index)
    return
        if($contentType = "json")
        then (
            $facet, json:array(
                for $item in $values
                return json:object((
                    "value", $item,
                    "count", cts:frequency($item)
                ))
            )
        )
        else if($contentType = "xml")
        then <facet name="{ $facet }">{
            for $item in $values
            return (
                <value>{ $item }</value>,
                <count>{ cts:frequency($item) }</count>
            )
        }</facet>
        else ()
return
    if($contentType = "json")
    then json:xmlToJSON(json:object($values))
    else if($contentType = "xml")
    then <results>{ $values }</results>
    else ()
