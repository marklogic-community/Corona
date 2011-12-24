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

import module namespace common="http://marklogic.com/corona/common" at "lib/common.xqy";
import module namespace search="http://marklogic.com/corona/search" at "lib/search.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "lib/constants.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";
declare namespace hs="http://marklogic.com/xdmp/status/host";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/corona/named-query.xqy"))

let $requestMethod := xdmp:get-request-method()
let $name := map:get($params, "name")
let $collections := map:get($params, "collection")
let $properties := map:get($params, "property")
let $matchingDocs := map:get($params, "matchingDoc")
let $stringQuery := map:get($params, "stringQuery")
let $structuredQuery := map:get($params, "structuredQuery")
let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $errors := (
    if($requestMethod = "GET" and exists($matchingDocs) and exists(($name, $properties, $collections)))
    then common:error("corona:INVALID-PARAMETER", "When supplying a matching document, requests can not contain name, property or collection parameters", $outputFormat)
    else (),
    if($requestMethod = "POST" and empty(($stringQuery, $structuredQuery)))
    then common:error("corona:MISSING-PARAMETER", "Must supply a string or structured query when creating a stored query", $outputFormat)
    else (),
    if($requestMethod = "POST" and empty($name))
    then common:error("corona:MISSING-PARAMETER", "Must supply a name when creating a stored query", $outputFormat)
    else (),
    if($requestMethod = "DELETE" and empty($name))
    then common:error("corona:MISSING-PARAMETER", "Must supply a name when deleting a stored query", $outputFormat)
    else ()
)


return common:output(
    if(exists($errors))
    then $errors
    else 

    if($requestMethod = "POST")
    then try {(
        xdmp:set-response-code(204, "Query inserted"),
        if(exists($stringQuery))
        then search:saveStringQuery($name, map:get($params, "description"), $stringQuery, $collections, common:processPropertiesParameter($properties), common:processPermissionParameter(map:get($params, "permission")))
        else if(exists($structuredQuery))
        then search:saveStructuredQuery($name, map:get($params, "description"), $structuredQuery, $collections, common:processPropertiesParameter($properties), common:processPermissionParameter(map:get($params, "permission")))
        else ()
    )}
    catch ($e) {
        common:errorFromException($e, $outputFormat)
    }

    else if($requestMethod = "GET")
    then try {
        let $start := map:get($params, "start")
        let $length := map:get($params, "length")
        let $value := map:get($params, "value")

        let $query := cts:and-query((
            cts:collection-query($const:StoredQueriesCollection),

            if(exists(map:get($params, "prefix")))
            then cts:element-attribute-value-query(xs:QName("corona:storedQuery"), xs:QName("prefix"), map:get($params, "prefix"), "exact")
            else (),

            if(string-length($name) > 0)
            then cts:element-attribute-value-query(xs:QName("corona:storedQuery"), xs:QName("name"), $name, "exact")
            else (),

            if(exists($properties))
            then cts:properties-query(cts:element-value-query(QName("http://marklogic.com/corona", $properties), $value, "exact"))
            else (),

            for $collection in $collections
            return cts:collection-query($collection),

            for $matchingDoc in $matchingDocs
            return cts:reverse-query(doc($matchingDoc))
        ))

        let $log := common:log("Named Query", "Fetching with", $query)

        let $end := $start + $length - 1
        let $results := cts:search(/corona:storedQuery, $query)[$start to $end]

        let $total :=
            if(exists($results[1]))
            then cts:remainder($results[1]) + $start - 1
            else 0

        let $start :=
            if($total = 0)
            then 0
            else $start
        let $end :=
            if($end > $total)
            then $total
            else $end

        let $executionTime := substring(string(xdmp:query-meters()/*:elapsed-time), 3, 4)
        return
            if($outputFormat = "json")
            then json:object((
                "meta", json:object((
                    "start", $start,
                    "end", $end,
                    "total", $total,
                    "executionTime", $executionTime
                )),
                "results", json:array((
                    for $result in $results
                    return json:object((
                        if(exists($result/@prefix)) then ("prefix", string($result/@prefix)) else (),
                        "name", string($result/@name),
                        "description", string($result/@description),
                        "queryType", string($result/@type),
                        "query", $result/corona:original/node()
                    ))
                ))
            ))
            else if($outputFormat = "xml")
            then <corona:response>
                <corona:meta>
                    <corona:start>{ $start }</corona:start>
                    <corona:end>{ $end }</corona:end>
                    <corona:total>{ $total }</corona:total>
                    <corona:executionTime>{ $executionTime }</corona:executionTime>
                </corona:meta>
                <corona:results>{
                    for $result in $results
                    return <corona:result>
                        { if(exists($result/@prefix)) then <corona:prefix>{ string($result/@prefix) }</corona:prefix> else () }
                        <corona:name>{ string($result/@name) }</corona:name>
                        <corona:description>{ string($result/@description) }</corona:description>
                        <corona:queryType>{ string($result/@type) }</corona:queryType>
                        <corona:query>{ $result/corona:original/node() }</corona:query>
                    </corona:result>
                }</corona:results>
            </corona:response>
            else ()
    }
    catch ($e) {
        common:errorFromException($e, $outputFormat)
    }

    else if($requestMethod = "DELETE")
    then try {
        search:deleteStoredQuery($name)
    }
    catch ($e) {
        common:errorFromException($e, $outputFormat)
    }

    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), $outputFormat)
)
