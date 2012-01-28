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


let $params := rest:process-request(endpoints:request("/corona/manage/schemas.xqy"))
let $requestMethod := xdmp:get-request-method()
let $uri := map:get($params, "uri")
let $schemaContent := xdmp:get-request-body("xml")/xs:schema

return common:output(
    if($requestMethod = "GET")
    then
        if(string-length($uri))
        then
            let $existing := manage:getSchema($uri)
            return
                if(exists($existing))
                then $existing
                else common:error("corona:SCHEMA-NOT-FOUND", "Schema not found", "json")
        else json:array(manage:getAllSchemaURIs())

    else if($requestMethod = "PUT")
    then
        if(string-length($uri))
        then
            try {
                manage:setSchema($uri, $schemaContent)
            }
            catch ($e) {
                common:errorFromException($e, "xml")
            }
        else common:error("corona:INVALID-PARAMETER", "Must specify a URI for the schema", "json")

    else if($requestMethod = "DELETE")
    then
        if(string-length($uri))
        then
            let $existing := manage:getSchema($uri)
            return
                if(exists($existing))
                then manage:deleteSchema($uri)
                else common:error("corona:SCHEMA-NOT-FOUND", "Schema not found", "json")
        else manage:deleteAllSchemas()
    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
)
