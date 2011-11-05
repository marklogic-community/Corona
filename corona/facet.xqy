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

import module namespace const="http://marklogic.com/corona/constants" at "lib/constants.xqy";
import module namespace config="http://marklogic.com/corona/index-config" at "lib/index-config.xqy";
import module namespace common="http://marklogic.com/corona/common" at "lib/common.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "lib/manage.xqy";
import module namespace search="http://marklogic.com/corona/search" at "lib/search.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace structquery="http://marklogic.com/corona/structured-query" at "lib/structured-query.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "lib/string-query.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/facet.xqy"))
let $facets := tokenize(map:get($params, "facets"), ",")
let $stringQuery := map:get($params, "stringQuery")
let $structuredQuery := map:get($params, "structuredQuery")

let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $limit := map:get($params, "limit")
let $order := map:get($params, "order")
let $frequency := map:get($params, "frequency")
let $includeAllValues := map:get($params, "includeAllValues")

let $test := (
    if(empty($stringQuery) and empty($structuredQuery))
    then common:error("corona:MISSING-PARAMETER", "Must supply either a string or a structured query", $outputFormat)
    else ()
)

let $query :=
    if(exists($stringQuery))
    then stringquery:parse($stringQuery)
    else if(exists($structuredQuery))
    then try {
        structquery:getCTS(structquery:getParseTree($structuredQuery), ())
    }
    catch ($e) {
        xdmp:set($test, common:error("corona:INVALID-PARAMETER", concat("The structured query JSON isn't valid: ", $e/*:message), $outputFormat))
    }
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
    if(exists($test))
    then ()
    else 

    for $facet in $facets

    let $rawQuery :=
        if(exists($stringQuery))
        then stringquery:getParseTree($stringQuery)
        else if(exists($structuredQuery))
        then structquery:getParseTree($structuredQuery)
        else ()

    let $valuesInQuery :=
        if(exists($stringQuery))
        then stringquery:valuesForFacet($rawQuery, $facet)
        else if(exists($structuredQuery))
        then structquery:valuesForFacet($rawQuery, $facet)
        else ()

    let $ignoreFacet :=
        if($includeAllValues = "yes")
        then $facet
        else ()

    let $query :=
        if(exists($stringQuery))
        then stringquery:getCTSFromParseTree($rawQuery, $ignoreFacet)
        else if(exists($structuredQuery))
        then structquery:getCTSFromParseTree($rawQuery, $ignoreFacet)
        else $query

    let $query := cts:and-query((
        $query,
        for $collection in map:get($params, "collection")
        return cts:collection-query($collection),
        for $directory in map:get($params, "underDirectory")
        let $directory :=
            if(ends-with($directory, "/"))
            then $directory
            else concat($directory, "/")
        return cts:directory-query($directory, "infinity"),
        for $directory in map:get($params, "inDirectory")
        let $directory :=
            if(ends-with($directory, "/"))
            then $directory
            else concat($directory, "/")
        return cts:directory-query($directory)
    ))

    let $index := config:get($facet)
    let $options :=
        if($includeAllValues = "yes" and $index/@type = ("bucketedrange", "autobucketedrange"))
        then ("empties", $options)
        else $options

    let $values :=
        if($index/@type = "range")
        then search:rangeIndexValues($index, $query, $options, $limit, $valuesInQuery, $outputFormat)
        else if($index/@type = ("bucketedrange", "autobucketedrange"))
        then search:bucketIndexValues($index, $query, $options, $limit, $valuesInQuery, $outputFormat)
        else ()

    where exists($index)
    return
        if($outputFormat = "json")
        then ($facet, $values)
        else if($outputFormat = "xml")
        then <corona:facet name="{ $facet }">{ $values }</corona:facet>
        else ()
return
    if(exists($test))
    then $test
    else if($outputFormat = "json")
    then json:serialize(json:object($values))
    else if($outputFormat = "xml")
    then <corona:results>{ $values }</corona:results>
    else ()
