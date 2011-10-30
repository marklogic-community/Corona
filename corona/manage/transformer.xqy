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


let $params := rest:process-request(endpoints:request("/corona/manage/transformer.xqy"))
let $requestMethod := xdmp:get-request-method()
let $name := map:get($params, "name")
let $bodyContent := xdmp:get-request-body("text")/text()

let $existing := manage:getTransformer($name)

return
    if($requestMethod = "GET")
    then
        if(exists($name))
        then
            if(exists($existing))
            then $existing
            else common:error("corona:TRANSFORMER-NOT-FOUND", "Transformer not found", "json")
        else json:serialize(json:array(manage:getAllTransformerNames()))

    else if($requestMethod = "PUT")
    then
        if(exists($name))
        then
            try {
                manage:setTransformer($name, $bodyContent)
            }
            catch ($e) {
                common:errorFromException($e, "xml")
            }
        else common:error("corona:INVALID-PARAMETER", "Must specify a name for the transformer", "json")

    else if($requestMethod = "DELETE")
    then
        if(exists($name))
        then
            if(exists($existing))
            then manage:deleteTransformer($name)
            else common:error("corona:TRANSFORMER-NOT-FOUND", "Transformer not found", "json")
        else common:error("corona:INVALID-PARAMETER", "Must specify the name of the transformer to delete", "json")
    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
