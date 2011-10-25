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
import module namespace const="http://marklogic.com/corona/constants" at "lib/constants.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "lib/string-query.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/stringQuery.xqy"))

let $stringQuery := map:get($params, "stringQuery")
let $include := map:get($params, "include")
let $filtered := map:get($params, "filtered")
let $contentType := map:get($params, "content-type")
let $extractPath := map:get($params, "extractPath")
let $applyTransform := map:get($params, "applyTransform")
let $start := map:get($params, "start")
let $end := map:get($params, "end")

let $test := (
    if(empty($stringQuery))
    then common:error(400, "corona:MISSING-PARAMETER", "Must supply a string query", $contentType)
    else if(exists($end) and exists($start) and $start > $end)
    then common:error(400, "corona:INVALID-PARAMETER", "The end must be greater than the start", $contentType)
    else ()
)

let $query := stringquery:parse($stringQuery)

let $query := cts:and-query((
    $query,
    if($contentType = "json")
    then cts:collection-query($const:JSONCollection)
    else if($contentType = "xml")
    then cts:collection-query($const:XMLCollection)
    else (),
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

let $options :=
    if($filtered)
    then "filtered"
    else "unfiltered"

let $results :=
    if($contentType = "json")
    then
        if(exists($start) and exists($end) and $end > $start)
        then cts:search(/json:json, $query, $options)[$start to $end]
        else if(exists($start))
        then cts:search(/json:json, $query, $options)[$start]
        else ()
    else if($contentType = "xml")
    then
        if(exists($start) and exists($end) and $end > $start)
        then cts:search(/*, $query, $options)[$start to $end]
        else if(exists($start))
        then cts:search(/*, $query, $options)[$start]
        else ()
    else ()

let $total :=
    if(exists($results[1]))
    then cts:remainder($results[1]) + $start - 1
    else 0

let $end :=
    if($end > $total)
    then $total
    else $end

return
    if(exists($test))
    then $test
    else if($contentType = "json")
    then reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $query, $extractPath, $applyTransform)
    else if($contentType = "xml")
    then reststore:outputMultipleXMLDocs($results, $start, $end, $total, $include, $query, $extractPath, $applyTransform)
    else ()