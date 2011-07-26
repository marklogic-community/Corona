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

declare option xdmp:mapping "false";

let $requestMethod := xdmp:get-request-method()
let $include := xdmp:get-request-field("include", "content")
let $start := xdmp:get-request-field("start")[1]
let $end := xdmp:get-request-field("end")[1]
let $returnPath := xdmp:get-request-field("returnpath")
let $query := string(xdmp:get-request-field("q", "{}")[1])
let $query :=
    if(string-length(normalize-space($query)) = 0)
    then "{}"
    else $query

let $start := if($start castable as xs:positiveInteger) then xs:positiveInteger($start) else 1
let $end := if($end castable as xs:positiveInteger) then xs:positiveInteger($end) else ()

return
    if($requestMethod = ("GET", "POST"))
    then customquery:execute($query, $include, $start, $end, $returnPath)
    else ()
