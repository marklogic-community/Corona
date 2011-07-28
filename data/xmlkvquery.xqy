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

import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "lib/date-parser.xqy";

declare option xdmp:mapping "false";

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

let $query := cts:and-query(
    for $key in xdmp:get-request-field-names()
    let $value := xdmp:get-request-field($key)

    let $bits := tokenize($key, "/@")
    let $element := $bits[1]
    let $attribute := $bits[2]

    where not(starts-with($key, "__MLJSONURL__:"))
    return
        if(exists($attribute))
        then cts:element-attribute-value-query(xs:QName($element), xs:QName($attribute), $value)
        else cts:element-value-query(xs:QName($element), $value)
)

let $results :=
    if(exists($start) and exists($end) and $end > $start)
    then cts:search(collection()/*, $query)[$start to $end]
    else if(exists($start))
    then cts:search(collection()/*, $query)[$start]
    else ()

let $total :=
    if(exists($results[1]))
    then cts:remainder($results[1]) + $start - 1
    else 0

let $end :=
    if($end > $total)
    then $total
    else $end

return reststore:outputMultipleXMLDocs($results, $start, $end, $total, ("content"), $query, ())
