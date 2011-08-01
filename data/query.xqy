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

import module namespace const="http://marklogic.com/mljson/constants" at "lib/constants.xqy";
import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

declare option xdmp:mapping "false";

let $query := xdmp:get-request-field("q", "")[1]
let $include := xdmp:get-request-field("include", "content")
let $contentType := xdmp:get-request-field("content-type")[1]
let $returnPath := xdmp:get-request-field("returnpath")[1]

let $start := xdmp:get-request-field("start")[1]
let $end := xdmp:get-request-field("end")[1]
let $start := if($start castable as xs:positiveInteger) then xs:positiveInteger($start) else 1
let $end := if($end castable as xs:positiveInteger) then xs:positiveInteger($end) else ()

let $query := parser:parse($query)

let $results :=
    if($contentType = "json")
    then
        if(exists($start) and exists($end) and $end > $start)
        then cts:search(collection($const:JSONCollection)/json:json, $query)[$start to $end]
        else if(exists($start))
        then cts:search(collection($const:JSONCollection)/json:json, $query)[$start]
        else ()
    else if($contentType = "xml")
    then
        if(exists($start) and exists($end) and $end > $start)
        then cts:search(collection($const:XMLCollection)/*, $query)[$start to $end]
        else if(exists($start))
        then cts:search(collection($const:XMLCollection)/*, $query)[$start]
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
    if($contentType = "json")
    then reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $query, $returnPath)
    else if($contentType = "xml")
    then reststore:outputMultipleXMLDocs($results, $start, $end, $total, $include, $query, $returnPath)
    else ()
