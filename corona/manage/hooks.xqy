(:
Copyright 2011 Swell Lines LLC

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


let $params := rest:process-request(endpoints:request("/corona/manage/hooks.xqy"))
let $requestMethod := xdmp:get-request-method()
let $insertTransformer := map:get($params, "insertTransformer")
let $fetchTransformer := map:get($params, "fetchTransformer")

let $transformerName :=
	if(string-length($insertTransformer))
	then $insertTransformer
	else if(string-length($fetchTransformer))
	then $fetchTransformer
	else ()

return common:output(
    try {
		if(exists($transformerName) and empty(manage:getTransformer($transformerName)))
		then common:error("corona:INVALID-PARAMETER", concat("No transformer with the name: '", $transformerName, "'"), "json")

		else if($requestMethod = "DELETE")
		then (
            let $hook := map:get($params, "hook")
            return
                if($hook = "insertTransformer")
                then manage:deleteInsertTransformer()
                else if($hook = "fetchTransformer")
                then manage:deleteFetchTransformer()
                else ()
        )
		else if($requestMethod = "POST")
		then (
			xdmp:set-response-code(204, "Hook saved"),

			if(exists($insertTransformer))
			then manage:setInsertTransformer($insertTransformer)
			else if(exists($fetchTransformer))
			then manage:setFetchTransformer($fetchTransformer)
			else common:error("corona:INVALID-PARAMETER", "Must specify a hook to set", "json")
		)
		else if($requestMethod = "GET")
		then json:object((
			if(exists(manage:getInsertTransformer()))
			then ("insertTransformer", manage:getInsertTransformer())
			else (),

			if(exists(manage:getFetchTransformer()))
			then ("fetchTransformer", manage:getFetchTransformer())
			else ()
		))
		else ()
    }
    catch ($e) {
        common:errorFromException($e, "json")
    }
)

