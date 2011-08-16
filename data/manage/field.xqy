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


let $params := rest:process-request(endpoints:request("/data/manage/field.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $database := xdmp:database()
let $config := admin:get-configuration()
let $existing := manage:getField($name, $config)

let $includeKeys := distinct-values(map:get($params, "includeKey"))
let $excludes := distinct-values(map:get($params, "excludeKey"))
let $includeElements := distinct-values(map:get($params, "includeElement"))
let $excludeElements := distinct-values(map:get($params, "excludeElement"))
let $mode := map:get($params, "mode")

return
    if($requestMethod = "GET")
    then
        if(exists($existing))
        then json:serialize($existing)
        else common:error(404, "Field not found", "json")

    else if($requestMethod = "POST")
    then (
        if(exists($existing))
        then xdmp:set($config, admin:database-delete-field($config, $database, $name))
        else (),
        try {
            manage:createField($name, $mode, $includeKeys, $excludes, $includeElements, $excludeElements, $config)
        }
        catch ($e) {
            common:error($e, "json")
        }
    )

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then manage:deleteField($name, $config)
        else common:error(404, "Field not found", "json")
    else common:error(500, concat("Unsupported method: ", $requestMethod), "json")
