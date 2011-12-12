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

import module namespace common="http://marklogic.com/corona/common" at "lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "lib/string-query.xqy";
import module namespace structquery="http://marklogic.com/corona/structured-query" at "lib/structured-query.xqy";
import module namespace store="http://marklogic.com/corona/store" at "lib/store.xqy";
import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";

import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";

declare option xdmp:mapping "false";


declare function local:queryFromRequest(
    $params as map:map
) as cts:query?
{
    let $structuredQuery :=
        try {
            structquery:getParseTree(map:get($params, "structuredQuery"))
        }
        catch ($e) {
            error(xs:QName("corona:INVALID-PARAMETER"), concat("The structured query JSON isn't valid: ", $e/*:message))
        }
    let $stringQuery :=
        try {
            stringquery:parse(map:get($params, "stringQuery"))
        }
        catch ($e) {
            error(xs:QName("corona:INVALID-PARAMETER"), concat("The string query isn't valid: ", $e/*:message))
        }
    return (stringquery:parse(map:get($params, "stringQuery")), structquery:getCTS($structuredQuery, (), false()))[1]
};

let $requestMethod := xdmp:get-request-method()
let $params := rest:process-request(endpoints:request("/corona/store-get.xqy"))
let $uri := map:get($params, "uri")
let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $doc := doc($uri)
let $errors :=
    if($requestMethod = ("GET") and string-length($uri) = 0)
    then common:error("corona:MISSING-PARAMETER", "Must supply a URI when inserting, updating or fetching a document", $outputFormat)
    else if(empty($doc))
    then common:error("corona:DOCUMENT-NOT-FOUND", concat("There is no document at '", $uri, "'"), $outputFormat)
    else if(not(common:validateOutputFormat($outputFormat)))
    then common:error("corona:INVALID-OUTPUT-FORMAT", concat("The output format '", $outputFormat, "' isn't valid"), "json")
    else ()

let $include := map:get($params, "include")
let $content :=
    if($requestMethod = "GET" and string-length($uri))
    then try {
        let $extractPath := map:get($params, "extractPath")
        let $transformer := map:get($params, "applyTransform")
        where empty($errors)
        return
            if($include = "content" and count($include) = 1)
            then $doc
            else if($outputFormat = "json")
            then store:outputDocument($doc, $include, $extractPath, $transformer, local:queryFromRequest($params), $outputFormat)
            else <corona:response>{ store:outputDocument($doc, $include, $extractPath, $transformer, local:queryFromRequest($params), $outputFormat)/* }</corona:response>
    }
    catch ($e) {
        xdmp:set($errors, common:errorFromException($e, $outputFormat))
    }
    else xdmp:set($errors, common:error("corona:INVALID-PARAMETER", "Unknown request", $outputFormat))

let $output := ($errors, $content)[1]
return
    if($output instance of binary())
    then common:output($output, store:getBinaryContentType($output))
    else common:output($output)
