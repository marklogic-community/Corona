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

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/corona/manage/contentitems.xqy"))
let $requestMethod := xdmp:get-request-method()
let $key := map:get($params, "key")
let $element := map:get($params, "element")
let $attribute := map:get($params, "attribute")
let $field := map:get($params, "field")
let $weight := map:get($params, "weight")
let $mode := map:get($params, "mode")

let $existing :=
    if(exists($key))
    then manage:getContentItem("key", $key, $mode)
    else if(exists($element) and exists($attribute))
    then manage:getContentItem("attribute", $element, $attribute, $mode)
    else if(exists($element))
    then manage:getContentItem("element", $element, $mode)
    else if(exists($field))
    then manage:getContentItem("field", $field, $mode)
    else ()

return
    if($requestMethod = "GET")
    then
        if(empty(($key, $element, $attribute, $field)))
        then json:serialize(json:array(manage:getAllContentItems()))
        else if(exists($existing))
        then json:serialize($existing)
        else common:error(404, "Content item not found", "json")

    else if($requestMethod = "POST")
    then
        try {
            if(exists($key))
            then manage:addContentItem("key", $key, $mode, $weight)
            else if(exists($element) and exists($attribute))
            then manage:addContentItem("attribute", $element, $attribute, $mode, $weight)
            else if(exists($element))
            then manage:addContentItem("element", $element, $mode, $weight)
            else if(exists($field))
            then manage:addContentItem("field", $field, $mode, $weight)
            else ()
        }
        catch ($e) {
            common:errorFromException(400, $e, "json")
        }

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then
            if(exists($key))
            then manage:deleteContentItem("key", $key, $mode)
            else if(exists($element) and exists($attribute))
            then manage:deleteContentItem("attribute", $element, $attribute, $mode)
            else if(exists($element))
            then manage:deleteContentItem("element", $element, $mode)
            else if(exists($field))
            then manage:deleteContentItem("field", $field, $mode)
            else ()
        else common:error(404, "Content item not found", "json")
    else common:error(500, concat("Unsupported method: ", $requestMethod), "json")
