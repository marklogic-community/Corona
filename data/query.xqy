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

import module namespace parser="http://marklogic.com/mljson/query-parser" at "lib/query-parser.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

declare option xdmp:mapping "false";

let $requestMethod := xdmp:get-request-method()
let $query := xdmp:get-request-field("q", "")[1]
let $include := xdmp:get-request-field("include", "content")
let $returnPath := xdmp:get-request-field("returnpath")

let $index := xdmp:get-request-field("__MLJSONURL__:index")
let $index :=
    if($index castable as xs:integer)
    then xs:integer($index)
    else 1

let $start := xdmp:get-request-field("__MLJSONURL__:start")
let $start :=
    if($start castable as xs:integer)
    then xs:integer($start)
    else $index

let $end := xdmp:get-request-field("__MLJSONURL__:end")
let $end :=
    if($end castable as xs:integer)
    then xs:integer($end)
    else $start

let $query := parser:parse($query)

let $results :=
    if(exists($start) and exists($end) and $end > $start)
    then cts:search(/json:json, $query)[$start to $end]
    else if(exists($start))
    then cts:search(/json:json, $query)[$start]
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
    if($requestMethod = "GET")
    then reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $query, $returnPath)
    else ()
