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


let $params := rest:process-request(endpoints:request("/corona/manage/namespace.xqy"))
let $prefix := map:get($params, "prefix")
let $uri := map:get($params, "uri")
let $requestMethod := xdmp:get-request-method()

let $existing := manage:getNamespaceURI($prefix)

return
    if($requestMethod = "GET")
    then
        if(exists($prefix))
        then
            if(exists($existing))
            then json:serialize($existing)
            else common:error(404, "corona:NAMESPACE-NOT-FOUND", "Namespace not found", "json")
        else json:serialize(json:array(manage:getAllNamespaces()))

    else if($requestMethod = "POST")
    then
        if(exists($prefix))
        then
            if(not(matches($prefix, "^[A-Za-z_][A-Za-z0-9_\.]*$")))
            then common:error(400, "corona:INVALID-PARAMETER", "Invalid namespace prefix", "json")
            else manage:setNamespaceURI($prefix, $uri)
        else common:error(400, "corona:INVALID-PARAMETER", "Must specify a prefix for the namespace", "json")

    else if($requestMethod = "DELETE")
    then
        if(exists($prefix))
        then
            if(exists($existing))
            then manage:deleteNamespace($prefix)
            else common:error(404, "common:NAMESPACE-NOT-FOUND", "Namespace not found", "json")
        else common:error(400, "corona:INVALID-PARAMETER", "Must specify a namespace prefix to delete", "json")
    else common:error(500, "corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
