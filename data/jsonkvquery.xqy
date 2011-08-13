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
import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "lib/date-parser.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/data/jsonkvquery.xqy"))

let $key := map:get($params, "key")
let $element := map:get($params, "element")
let $attribute := map:get($params, "attribute")
let $value := map:get($params, "value")

let $start := map:get($params, "start")
let $end := map:get($params, "end")
let $include := map:get($params, "include")
let $extractPath := map:get($params, "extractPath")

let $query :=
    if(exists($key))
    then
        if(json:castAs($key, true()) = "date")
        then
            let $date := dateparser:parse($value)
            return
                if(empty($date))
                then cts:element-value-query(xs:QName(concat("json:", json:escapeNCName($key))), $value, "exact")
                else cts:element-attribute-value-query(xs:QName(concat("json:", json:escapeNCName($key))), xs:QName("normalized-date"), $date, "exact")

        else if($value = ("true", "false"))
        then cts:or-query((
            cts:element-value-query(xs:QName(concat("json:", json:escapeNCName($key))), $value, "exact"),
            cts:element-attribute-value-query(xs:QName(concat("json:", json:escapeNCName($key))), xs:QName("boolean"), $value, "exact")
        ))

        else cts:element-value-query(xs:QName(concat("json:", json:escapeNCName($key))), $value, "exact")
    else if(exists($element) and exists($attribute))
    then cts:element-attribute-value-query(xs:QName($element), xs:QName($attribute), $value, "exact")
    else if(exists($element))
    then cts:element-value-query(xs:QName($element), $value, "exact")
    else ()

let $results :=
    if(exists($start) and exists($end) and $end > $start)
    then cts:search(collection($const:JSONCollection)/json:json, $query)[$start to $end]
    else if(exists($start))
    then cts:search(collection($const:JSONCollection)/json:json, $query)[$start]
    else ()

let $total :=
    if(exists($results[1]))
    then cts:remainder($results[1]) + $start - 1
    else 0

let $end :=
    if($end > $total)
    then $total
    else $end

return reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $query, $extractPath, ())
