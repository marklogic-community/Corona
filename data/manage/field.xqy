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
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/data/jsonstore.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $database := xdmp:database()
let $config := admin:get-configuration()
let $existing :=
    try {
        admin:database-get-field($config, $database, $name)
    }
    catch ($e) {()}

return
    if($requestMethod = "GET")
    then
        if(exists($existing))
        then json:xmlToJSON(manage:fieldDefinitionToJsonXml($existing))
        else common:error(404, "Field not found")

    else if($requestMethod = ("PUT", "POST"))
    then 
        if(exists(manage:validateIndexName($name)))
        then common:error(500, manage:validateIndexName($name))
        else (
            if(exists($existing))
            then xdmp:set($config, admin:database-delete-field($config, $database, $name))
            else (),

            let $setProp := prop:set(concat("index-", $name), concat("field/", $name))
            let $config := admin:database-add-field($config, $database, admin:database-field($name, false()))
            let $includes := xdmp:get-request-field("include")
            let $excludes := xdmp:get-request-field("exclude")
            let $add :=
                for $include in $includes
                let $include := json:escapeNCName($include)
                let $el := admin:database-included-element("http://marklogic.com/json", $include, 1, (), "", "")
                return xdmp:set($config, admin:database-add-field-included-element($config, $database, $name, $el))
            let $add :=
                for $exclude in $excludes
                let $el := admin:database-excluded-element("http://marklogic.com/json", $exclude)
                return xdmp:set($config, admin:database-add-field-excluded-element($config, $database, $name, $el))
            return admin:save-configuration($config)
        )

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then (
            admin:save-configuration(admin:database-delete-field($config, $database, $name)),
            prop:delete(concat("index-", $name))
        )
        else common:error(404, "Field not found")
    else ()
