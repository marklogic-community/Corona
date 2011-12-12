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
import module namespace manage="http://marklogic.com/corona/manage" at "lib/manage.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "lib/constants.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "lib/string-query.xqy";
import module namespace structquery="http://marklogic.com/corona/structured-query" at "lib/structured-query.xqy";
import module namespace store="http://marklogic.com/corona/store" at "lib/store.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/search.xqy"))

let $stringQuery := map:get($params, "stringQuery")
let $structuredQuery := map:get($params, "structuredQuery")
let $include := map:get($params, "include")
let $filtered := map:get($params, "filtered")
let $extractPath := map:get($params, "extractPath")
let $applyTransform := map:get($params, "applyTransform")
let $start := map:get($params, "start")
let $length := map:get($params, "length")
let $txid := map:get($params, "txid")

let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $errors := (
    if(empty(($stringQuery, $structuredQuery)) or (exists($structuredQuery) and string-length(normalize-space($structuredQuery)) = 0))
    then common:error("corona:MISSING-PARAMETER", "Must supply a string query or a structured query", $outputFormat)
    else ()
)

let $structuredQueryJSON :=
    if(exists($structuredQuery))
    then
        try {
            structquery:getParseTree($structuredQuery)
        }
        catch ($e) {
            xdmp:set($errors, common:error("corona:INVALID-PARAMETER", concat("The structured query JSON isn't valid: ", $e/*:message), $outputFormat))
        }
    else ()
return
    if(exists($errors))
    then $errors
    else if(not(common:transactionsMatch($txid)))
    then xdmp:invoke("/corona/search.xqy", (), <options xmlns="xdmp:eval"><transaction-id>{ map:get(common:processTXID($txid, true()), "id") }</transaction-id></options>)
    else

let $query :=
    if(exists($stringQuery))
    then stringquery:parse($stringQuery)
    else if(exists($structuredQuery))
    then structquery:getCTS($structuredQueryJSON)
    else ()

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

let $options :=
    if($filtered)
    then "filtered"
    else "unfiltered"

let $end := $start + $length - 1

let $results := cts:search(doc(), $query, $options)[$start to $end]

let $total :=
    if(exists($results[1]))
    then cts:remainder($results[1]) + $start - 1
    else 0

let $end :=
    if($end > $total)
    then $total
    else $end

let $highlightQuery :=
    if(exists($structuredQueryJSON) and structquery:containsNamedQuery($structuredQueryJSON))
    then structquery:getCTS($structuredQueryJSON, (), false())
    else $query

let $results :=
    try {
        store:outputMultipleDocuments($results, $start, $end, $total, $include, $query, $extractPath, $applyTransform, $outputFormat)
    }
    catch ($e) {
        xdmp:set($errors, common:errorFromException($e, $outputFormat))
    }

return common:output(($errors, $results)[1])
