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

let $property := prop:get(concat("index-", $name))
let $property :=
    if(starts-with($property, concat("range/", $name, "/")))
    then $property
    else ()

let $bits := tokenize($property, "/")
let $key := xdmp:get-request-field("key", $bits[3])
let $type := xdmp:get-request-field("type", $bits[4])
(: If the type is boolean, the operator should always be equality :)
let $operator :=
    if($type = "boolean")
    then "eq"
    else xdmp:get-request-field("operator", $bits[5])
let $xsType := manage:jsonTypeToSchemaType($type)

let $existingIndexes := admin:database-get-range-element-indexes($config, $database)
let $existing :=
    for $index in $existingIndexes
    where $index/*:scalar-type = $xsType and $index/*:namespace-uri = "http://marklogic.com/json" and $index/*:localname = $key
    return $index

return
    if($requestMethod = "GET")
    then
        if(exists($existing))
        then json:xmlToJSON(manage:rangeDefinitionToJsonXml($existing, $name, $operator))
        else common:error(404, "Range index not found")

    else if($requestMethod = ("PUT", "POST"))
    then
        if(exists(manage:validateIndexName($name)))
        then common:error(500, manage:validateIndexName($name))
        else (
            if(exists($existing))
            then ()
            else if($type = "boolean")
            then
                let $index := admin:database-range-element-attribute-index("boolean", "http://marklogic.com/json", $key, (), "boolean", "", false())
                let $config := admin:database-add-range-element-attribute-index($config, $database, $index)
                return admin:save-configuration($config)
            else
                let $colation :=
                    if($xsType = "string")
                    then "http://marklogic.com/collation/"
                    else ""
                let $index := admin:database-range-element-index($xsType, "http://marklogic.com/json", $key, $colation, false())
                let $config := admin:database-add-range-element-index($config, $database, $index)
                return admin:save-configuration($config)
            ,
            prop:set(concat("index-", $name), concat("range/", $name, "/", $key, "/", $type, "/", $operator))
        )

    else if($requestMethod = "DELETE")
    then
        if(exists($existing))
        then
            let $propertiesForIndex := manage:getPropertiesAssociatedWithRangeIndex($existing)
            let $deleteIndex :=
                if(count($propertiesForIndex) = 1)
                then admin:save-configuration(admin:database-delete-range-element-index($config, $database, $existing))
                else ()
            return prop:delete(concat("index-", $name))
        else common:error(404, "Range index not found")
    else ()

