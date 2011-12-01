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


let $params := rest:process-request(endpoints:request("/corona/manage/range.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $config := admin:get-configuration()
let $existing := manage:getRange($name)

return common:output(
    if($requestMethod = "GET")
    then
        if(string-length($name))
        then
            if(exists($existing))
            then $existing
            else common:error("corona:RANGE-INDEX-NOT-FOUND", "Range index not found", "json")
        else json:array(manage:getAllRanges())

    else if($requestMethod = "POST")
    then
        if(string-length($name))
        then
            let $key := map:get($params, "key")
            let $element := map:get($params, "element")
            let $attribute := map:get($params, "attribute")
            let $type := map:get($params, "type")
            return

            if((empty($key) and empty($element)) or (exists($key) and exists($element)))
            then common:error("corona:MISSING-PARAMETER", "Must supply either a JSON key, an XML element name or XML element and attribute names", "json")
            else if(exists($attribute) and empty($element))
            then common:error("corona:MISSING-PARAMETER", "Must supply an XML element along with an XML attribute", "json")
            else
                try {
                    if(exists($key))
                    then manage:createJSONRange($name, $key, $type, map:get($params, "collation"), $config)
                    else if(exists($element) and exists($attribute))
                    then manage:createXMLAttributeRange($name, $element, $attribute, $type, map:get($params, "collation"), $config)
                    else if(exists($element) and empty($attribute))
                    then manage:createXMLElementRange($name, $element, $type, map:get($params, "collation"), $config)
                    else ()
                }
                catch ($e) {
                    common:errorFromException($e, "json")
                }
        else common:error("corona:INVALID-PARAMETER", "Must specify a name for the range", "json")

    else if($requestMethod = "DELETE")
    then
        if(string-length($name))
        then
            if(exists($existing))
            then manage:deleteRange($name, $config)
            else common:error("corona:RANGE-INDEX-NOT-FOUND", "Range index not found", "json")
        else manage:deleteAllRanges()
    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
)
