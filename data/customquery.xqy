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

import module namespace customquery="http://marklogic.com/mljson/custom-query" at "lib/custom-query.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/data/query.xqy"))

let $requestMethod := xdmp:get-request-method()
let $include := map:get($params, "include")
let $contentType := map:get($params, "content-type")
let $start := map:get($params, "start")
let $end := map:get($params, "end")
let $extractPath := map:get($params, "extractPath")
let $applyTransform := map:get($params, "applyTransform")
let $query := string(map:get($params, "q"))
let $query :=
    if(string-length(normalize-space($query)) = 0)
    then "{}"
    else $query

return
    if($requestMethod = ("GET", "POST"))
    then
        if($contentType = "json")
        then customquery:searchJSON($query, $include, $start, $end, $extractPath, $applyTransform)
        else if($contentType = "xml")
        then customquery:searchXML($query, $include, $start, $end, $extractPath, $applyTransform)
        else ()
    else ()
