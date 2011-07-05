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

import module namespace prop="http://xqdev.com/prop" at "../lib/properties.xqy";
import module namespace rest="http://marklogic.com/appservices/rest" at "../lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/data/jsonstore.xqy"))
let $name := map:get($params, "name")
let $key := map:get($params, "key")
let $mode := map:get($params, "mode")
let $requestMethod := xdmp:get-request-method()

let $existing := prop:get(concat("index-", $name))

return
    if($requestMethod = "GET")
    then
        if(exists($existing))
        then
            let $bits := tokenize($existing, "/")
            return json:xmlToJSON(json:object((
                "name", $name,
                "key", $bits[3],
                "mode", $bits[4] 
            )))
        else common:error(404, "Alias not found")

    else if($requestMethod = ("PUT", "POST"))
    then 
        if(exists(manage:validateIndexName($name)))
        then common:error(500, manage:validateIndexName($name))
        else prop:set(concat("index-", $name), concat("map/", $name, "/", $key, "/", $mode))

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then prop:delete(concat("index-", $name))
        else common:error(404, "Alias not found")
    else ()
