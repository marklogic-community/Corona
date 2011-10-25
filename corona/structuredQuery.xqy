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
import module namespace structquery="http://marklogic.com/corona/structured-query" at "lib/structured-query.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/query.xqy"))

let $requestMethod := xdmp:get-request-method()
let $include := map:get($params, "include")
let $contentType := map:get($params, "content-type")
let $start := map:get($params, "start")
let $end := map:get($params, "end")
let $extractPath := map:get($params, "extractPath")
let $applyTransform := map:get($params, "applyTransform")
let $query := string(map:get($params, "q"))

let $test := (
    if(empty($query) or string-length($query) = 0)
    then common:error(400, "corona:MISSING-PARAMETER", "Must supply a structured query", $contentType)
    else if(exists($end) and exists($start) and $start > $end)
    then common:error(400, "corona:INVALID-PARAMETER", "The end must be greater than the start", $contentType)
    else ()
)

let $query :=
    if(string-length(normalize-space($query)) = 0)
    then "{}"
    else $query

let $json := try {
        structquery:getParseTree($query)
    }
    catch ($e) {
        xdmp:set($test, common:error(400, "corona:INVALID-PARAMETER", concat("The query JSON isn't valid: ", $e/*:message), $contentType))
    }

where $requestMethod = ("GET", "POST")
return
    if(exists($test))
    then $test
    else if($contentType = "json")
    then structquery:searchJSON($json, $include, $start, $end, $extractPath, $applyTransform)
    else if($contentType = "xml")
    then structquery:searchXML($json, $include, $start, $end, $extractPath, $applyTransform)
    else ()
