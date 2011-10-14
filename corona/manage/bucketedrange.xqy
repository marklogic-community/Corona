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

import module namespace manage="http://marklogic.com/corona/manage" at "../lib/manage.xqy";
import module namespace common="http://marklogic.com/corona/common" at "../lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "../lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "../lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/corona/manage/bucketedrange.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $config := admin:get-configuration()
let $existing := manage:getBucketedRange($name)

return
    if($requestMethod = "GET")
    then
        if(exists($name))
        then
            if(exists($existing))
            then json:serialize($existing)
            else common:error(404, "corona:RANGE-INDEX-NOT-FOUND", "Bucketed range index not found", "json")
    else json:serialize(json:array(manage:getAllBucketedRanges()))

    else if($requestMethod = "POST")
    then
        if(exists($name))
        then
            let $key := map:get($params, "key")
            let $element := map:get($params, "element")
            let $attribute := map:get($params, "attribute")
            let $type := map:get($params, "type")
            let $bucketString := map:get($params, "buckets")
            let $buckets :=
                (: doesn't look like the server supports negative lookbehind, hence this sad hack :)
                let $bucketString := replace($bucketString, "\\\|", "____________PIPE____________")
                let $bucketString := replace($bucketString, "\\\\", "\\")
             
                for $bit at $pos in tokenize($bucketString, "\|")
                let $bit := replace($bit, "____________PIPE____________", "|")
                return 
                   if($pos mod 2)
                   then <label>{ $bit }</label>
                   else <boundary>{ $bit }</boundary>

            let $mode :=
                if(exists($key))
                then "json"
                else if(exists($element) and exists($attribute))
                then "xmlattribute"
                else "xmlelement"

            let $format := map:get($params, "format")
            let $firstFormat := map:get($params, "firstFormat")
            let $lastFormat := map:get($params, "lastFormat")

            let $bucketInterval := map:get($params, "bucketInterval")
            let $startingAt := map:get($params, "startingAt")
            let $stoppingAt := map:get($params, "stoppingAt")
            return

            if((empty($key) and empty($element)) or (exists($key) and exists($element)))
            then common:error(400, "corona:MISSING-PARAMETER", "Must supply either a JSON key or XML element name", "json")
            else if(exists($attribute) and empty($element))
            then common:error(400, "corona:MISSING-PARAMETER", "Must supply an XML element along with an XML attribute", "json")
            else if(exists($bucketInterval) and exists($startingAt) and $type = ("date", "dateTime"))
            then
                if(empty($firstFormat))
                then common:error(400, "corona:MISSING-PARAMETER", "Must supply a firstFormat when creating a auto-bucketed range index", "json")
                else if(empty($format))
                then common:error(400, "corona:MISSING-PARAMETER", "Must supply a format when creating a auto-bucketed range index", "json")
                else if(empty($lastFormat))
                then common:error(400, "corona:MISSING-PARAMETER", "Must supply a lastFormat when creating a auto-bucketed range index", "json")
                else

                if($mode = "json")
                then manage:createJSONAutoBucketedRange($name, $key, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat, $config)
                else if($mode = "xmlattribute")
                then manage:createXMLAttributeAutoBucketedRange($name, $element, $attribute, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat, $config)
                else if($mode = "xmlelement")
                then manage:createXMLElementAutoBucketedRange($name, $element, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat, $config)
                else ()
            else if(exists($buckets))
            then
                if($mode = "json")
                then manage:createJSONBucketedRange($name, $key, $type, $buckets, $config)
                else if($mode = "xmlattribute")
                then manage:createXMLAttributeBucketedRange($name, $element, $attribute, $type, $buckets, $config)
                else if($mode = "xmlelement")
                then manage:createXMLElementBucketedRange($name, $element, $type, $buckets, $config)
                else ()
            else common:error(400, "corona:MISSING-PARAMETER", "Must supply either the bucket definitions or a bucket interval with a starting date", "json")
        else common:error(400, "corona:MISSING-PARAMETER", "Must supply a name for the bucketed range", "json")

    else if($requestMethod = "DELETE")
    then
        if(exists($name))
        then
            if(exists($existing))
            then manage:deleteBucketedRange($name, $config)
            else common:error(404, "corona:RANGE-INDEX-NOT-FOUND", "Bucketed range index not found", "json")
        else common:error(400, "corona:MISSING-PARAMETER", "Must supply the name of the bucketed range to delete", "json")
    else common:error(500, "corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
