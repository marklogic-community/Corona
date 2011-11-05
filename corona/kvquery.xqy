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
import module namespace manage="http://marklogic.com/corona/manage" at "lib/manage.xqy";
import module namespace store="http://marklogic.com/corona/store" at "lib/store.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "lib/date-parser.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/kvquery.xqy"))


let $key := map:get($params, "key")
let $element := map:get($params, "element")
let $attribute := map:get($params, "attribute")
let $property := map:get($params, "property")
let $value := map:get($params, "value")

let $start := map:get($params, "start")
let $length := map:get($params, "length")
let $include := map:get($params, "include")
let $extractPath := map:get($params, "extractPath")
let $applyTransform := map:get($params, "applyTransform")

let $outputFormat := map:get($params, "outputFormat")

let $test := (
    if(exists($attribute) and empty($element))
    then common:error("corona:MISSING-PARAMETER", "Must supply the parent element name when searching for an attribute value", $outputFormat)
    else if((exists($key) or exists($element) or exists($property)) and empty($value))
    then common:error("corona:MISSING-PARAMETER", "Must supply a value along with the key, element, element/attribute or property", $outputFormat)
    else if(exists($value) and empty($key) and empty($element) and empty($property))
    then common:error("corona:MISSING-PARAMETER", "Must supply a key, element, element/attribute or property along with the value", $outputFormat)
    else ()
)

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
    else if(exists($property))
    then cts:properties-query(cts:element-value-query(QName("http://marklogic.com/corona", $property), $value, "exact"))
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

let $end := $start + $length - 1

let $results := cts:search(doc(), $query)[$start to $end]

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
    else store:outputMultipleDocuments($results, $start, $end, $total, $include, $query, $extractPath, $applyTransform, $outputFormat)
