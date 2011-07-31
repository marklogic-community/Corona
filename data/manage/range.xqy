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

import module namespace manage="http://marklogic.com/mljson/manage" at "../lib/manage.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "../lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "../lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "../lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/data/manage/range.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $config := admin:get-configuration()
let $existing := manage:getRange($name)

return
    if($requestMethod = "GET")
    then
        if(exists($existing))
        then json:xmlToJSON($existing)
        else common:error(404, "Range index not found", "json")

    else if($requestMethod = "POST")
    then
        let $key := map:get($params, "key")
        let $element := map:get($params, "element")
        let $attribute := map:get($params, "element")
        let $type := map:get($params, "type")
        let $operator := map:get($params, "operator")
        return

        if((empty($key) and empty($element)) or (exists($key) and exists($element)))
        then common:error(500, "Must supply either a JSON key or XML element name", "json")
        else if(exists($attribute) and empty($element))
        then common:error(500, "Must supply an XML element along with an XML attribute", "json")
        else if(exists($key) and not($type = ("string", "date", "number")))
        then common:error(500, "Valid JSON types are: string, date and number", "json")
        else if(exists($element) and not($type = ("int", "unsignedInt", "long", "unsignedLong", "float", "double", "decimal", "dateTime", "time", "date", "gYearMonth", "gYear", "gMonth", "gDay", "yearMonthDuration", "dayTimeDuration", "string", "anyURI")))
        then common:error(500, "Valid XML types are: int, unsignedInt, long, unsignedLong, float, double, decimal, dateTime, time, date, gYearMonth, gYear, gMonth, gDay, yearMonthDuration, dayTimeDuration, string and anyURI", "json")
        else if(exists(manage:validateIndexName($name)))
        then common:error(500, manage:validateIndexName($name), "json")
        else if(exists($existing))
        then common:error(500, "Range index with this configuration already exists", "json")
        else if(exists($key))
        then manage:createJSONRange($name, $key, $type, $operator, $config)
        else if(exists($element) and exists($attribute))
        then manage:createXMLAttributeRange($name, $element, $attribute, $type, $operator, $config)
        else if(exists($element) and empty($attribute))
        then manage:createXMLElementRange($name, $element, $type, $operator, $config)
        else ()

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then manage:deleteRange($name, $config)
        else common:error(404, "Range index not found", "json")
    else ()

