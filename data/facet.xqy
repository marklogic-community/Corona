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
import module namespace search="http://marklogic.com/mljson/search" at "lib/search.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace customquery="http://marklogic.com/mljson/custom-query" at "lib/custom-query.xqy";
import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/data/facet.xqy"))
let $facets := tokenize(map:get($params, "facets"), ",")
let $contentType := map:get($params, "content-type")
let $queryString := map:get($params, "q")
let $customQuery := map:get($params, "customquery")

let $limit := map:get($params, "limit")
let $order := map:get($params, "order")
let $frequency := map:get($params, "frequency")
let $includeAllValues := map:get($params, "includeAllValues")

    
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

    let $rawQuery :=
        if(exists($queryString))
        then parser:getParseTree($queryString)
        else if(exists($customQuery))
        then customquery:getParseTree($customQuery)
        else ()

    let $valuesInQuery :=
        if(exists($queryString))
        then parser:valuesForFacet($rawQuery, $facet)
        else if(exists($customQuery))
        then customquery:valuesForFacet($rawQuery, $facet)
        else ()

    let $ignoreFacet :=
        if($includeAllValues = "yes")
        then $facet
        else ()

    let $query :=
        if(exists($queryString))
        then parser:getCTSFromParseTree($rawQuery, $ignoreFacet)
        else if(exists($customQuery))
        then customquery:getCTSFromParseTree($rawQuery, $ignoreFacet)
        else $query

    let $index := config:get($facet)
    let $options :=
        if($includeAllValues = "yes" and $index/@type = ("bucketedrange", "autobucketedrange"))
        then ("empties", $options)
        else $options

    let $values :=
        if($index/@type = "range")
        then search:rangeIndexValues($index, $query, $options, $limit)
        else if($index/@type = ("bucketedrange", "autobucketedrange"))
        then search:bucketIndexValues($index, $query, $options, $limit, $valuesInQuery, $contentType)
        else ()

    where exists($index)
    return
        if($contentType = "json" and $index/@type = "range")
        then (
            $facet, json:array(
                for $item in $values
                return json:object((
                    "value", $item,
                    "inQuery", $item = $valuesInQuery,
                    "count", cts:frequency($item)
                ))
            )
        )
        else if($contentType = "json" and $index/@type = ("bucketedrange", "autobucketedrange"))
        then ($facet, $values)

        else if($contentType = "xml" and $index/@type = "range")
        then <facet name="{ $facet }">{
            for $item in $values
            return <result>
                <value>{ $item }</value>
                <inQuery>{ $item = $valuesInQuery }</inQuery>
                <count>{ cts:frequency($item) }</count>
            </result>
        }</facet>

        else if($contentType = "xml" and $index/@type = ("bucketedrange", "autobucketedrange"))
        then $values 

        else ()
return
    if($contentType = "json")
    then json:xmlToJSON(json:object($values))
    else if($contentType = "xml")
    then <results>{ $values }</results>
    else ()
