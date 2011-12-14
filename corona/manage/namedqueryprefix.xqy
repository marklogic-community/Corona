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


let $params := rest:process-request(endpoints:request("/corona/manage/namedqueryprefix.xqy"))
let $prefix := map:get($params, "prefix")
let $requestMethod := xdmp:get-request-method()
let $set := xdmp:set-response-code(if($requestMethod = "GET") then 200 else 204, "Named query prefix")

return common:output(
    if($requestMethod = "GET")
    then
        if(string-length($prefix))
        then
            if(manage:namedQueryPrefixExists($prefix))
            then json:object(("exists", true()))
            else common:error("corona:NAMED-QUERY-PREFIX-NOT-FOUND", "Named query prefix not found", "json")
        else json:array(manage:getNamedQueryPrefixs())

    else if($requestMethod = "POST")
    then
        if(string-length($prefix))
        then
            if(not(matches($prefix, "^[A-Za-z_][A-Za-z0-9]*$")))
            then common:error("corona:INVALID-PARAMETER", "Invalid named query prefix", "json")
            else manage:addNamedQueryPrefix($prefix)
        else common:error("corona:INVALID-PARAMETER", "Must specify a named query prefix", "json")

    else if($requestMethod = "DELETE")
    then
        if(string-length($prefix))
        then
            if(manage:namedQueryPrefixExists($prefix))
            then manage:removeNamedQueryPrefix($prefix)
            else common:error("corona:NAMED-QUERY-PREFIX-NOT-FOUND", "Named query prefix not found", "json")
        else common:error("corona:INVALID-PARAMETER", "Must specify a named query prefix", "json")
    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
)
