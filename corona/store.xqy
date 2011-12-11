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


declare function local:qualityFromRequest(
    $params as map:map
) as xs:integer?
{
    let $quality := map:get($params, "quality")
    where exists($quality)
    return
        if($quality castable as xs:integer)
        then xs:integer($quality)
        else error(xs:QName("corona:INVALID-PARAMETER"), "Document quality must be an integer")
};

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
    return (stringquery:parse(map:get($params, "stringQuery")), structquery:getCTS($structuredQuery))[1]
};

let $requestMethod := xdmp:get-request-method()
let $params := rest:process-request(endpoints:request("/corona/store.xqy"))
let $uri := map:get($params, "uri")
let $txid := map:get($params, "txid")
let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $errors :=
    if($requestMethod = ("PUT", "POST", "GET") and string-length($uri) = 0)
    then common:error("corona:INVALID-PARAMETER", "Must supply a URI when inserting, updating or fetching a document", $outputFormat)
    else if(not(common:validateOutputFormat($outputFormat)))
    then common:error("corona:INVALID-OUTPUT-FORMAT", concat("The output format '", $outputFormat, "' isn't valid"), "json")
    else ()

return
    if(exists($errors))
    then $errors
    else if(not(common:transactionsMatch($txid)))
    then xdmp:invoke("/corona/store.xqy", (), <options xmlns="xdmp:eval"><transaction-id>{ map:get(common:processTXID($txid, true()), "id") }</transaction-id></options>)
    else
        let $output :=
        if($requestMethod = "DELETE")
        then try {
            let $query := local:queryFromRequest($params)
            let $include := map:get($params, "include")
            return
                if(string-length($uri))
                then store:deleteDocument($uri, map:get($params, "include") = ("uri", "uris"), $outputFormat)
                else if(exists($query))
                then store:deleteDocumentsWithQuery($query, map:get($params, "bulkDelete"), map:get($params, "include") = ("uri", "uris"), map:get($params, "limit"), $outputFormat)
                else error(xs:QName("corona:MISSING-PARAMETER"), "Missing parameters: Must supply a URI, a string query or a structured query with DELETE requests")
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }

        else if($requestMethod = "GET" and string-length($uri))
        then try {
            let $documentType := store:getDocumentType($uri)
            let $include := map:get($params, "include")
            let $extractPath := map:get($params, "extractPath")
            let $applyTransform := map:get($params, "applyTransform")
            let $doc := doc($uri)
            return
                if(empty($doc))
                then common:error("corona:DOCUMENT-NOT-FOUND", concat("There is no document at '", $uri, "'"), $outputFormat)
                else if($include = "content" and count($include) = 1)
                then $doc
                else if($outputFormat = "json")
                then store:outputDocument($doc, $include, $extractPath, $applyTransform, local:queryFromRequest($params), $outputFormat)
                else <corona:response>{ store:outputDocument($doc, $include, $extractPath, $applyTransform, local:queryFromRequest($params), $outputFormat)/* }</corona:response>
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }

        else if($requestMethod = "PUT" and string-length($uri))
        then try {
            let $contentType := common:getContentType($uri, map:get($params, "contentType"))
            let $bodyContent :=
                if($contentType = "binary")
                then xdmp:get-request-body("binary")/binary()
                else xdmp:get-request-body("text")/text()
            let $applyTransform := map:get($params, "applyTransform")
            let $respondWithContent := map:get($params, "respondWithContent")
            let $test :=
                if(empty($bodyContent))
                then error(xs:QName("corona:INVALID-REQUEST"), "Missing document body")
                else ()
            let $collections := map:get($params, "collection")
            let $properties := common:processPropertiesParameter(map:get($params, "property"))
            let $permissions := common:processPermissionParameter(map:get($params, "permission"))
            let $quality := local:qualityFromRequest($params)
            let $set := xdmp:set-response-code(if($respondWithContent) then 200 else 204, "Document inserted")
            return
                if($contentType = "binary")
                then store:insertBinaryDocument($uri, $bodyContent, map:get($params, "contentForBinary"), $collections, $properties, $permissions, $quality, map:get($params, "extractMetadata"), map:get($params, "extractContent"), $applyTransform, $respondWithContent)
                else store:insertDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality, $contentType, $applyTransform, $respondWithContent)
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }

        else if($requestMethod = "POST" and string-length($uri))
        then try {
            let $contentType := common:getContentType($uri, map:get($params, "contentType"))
            let $bodyContent :=
                if($contentType = "binary")
                then xdmp:get-request-body("binary")/binary()
                else xdmp:get-request-body("text")/text()
            let $applyTransform := map:get($params, "applyTransform")
            let $respondWithContent := map:get($params, "respondWithContent")
            let $collections := map:get($params, "collection")
            let $properties := common:processPropertiesParameter(map:get($params, "property"))
            let $permissions := common:processPermissionParameter(map:get($params, "permission"))
            let $quality := local:qualityFromRequest($params)

            let $addCollections := map:get($params, "addCollection")
            let $addProperties := common:processPropertiesParameter(map:get($params, "addProperty"))
            let $addPermisssions := common:processPermissionParameter(map:get($params, "addPermission"))

            let $removeCollections := map:get($params, "removeCollection")
            let $removeProperties := map:get($params, "removeProperty")
            let $removePermissions := common:processPermissionParameter(map:get($params, "removePermission"))

            let $set := xdmp:set-response-code(if($respondWithContent) then 200 else 204, "Document updated")
            return
                if(exists($uri) and exists(map:get($params, "moveTo")))
                then store:moveDocument($uri, map:get($params, "moveTo"))
                else (
                    if(empty(doc($uri)) and exists($bodyContent))
                    then
                        if($contentType = "binary")
                        then store:insertBinaryDocument($uri, $bodyContent, map:get($params, "contentForBinary"), $collections, $properties, $permissions, $quality, map:get($params, "extractMetadata"), map:get($params, "extractContent"), $applyTransform, $respondWithContent)
                        else store:insertDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality, $contentType, $applyTransform, $respondWithContent)
                    else if(exists($bodyContent))
                    then
                        if($contentType = "binary")
                        then store:updateBinaryDocumentContent($uri, $bodyContent, map:get($params, "contentForBinary"), map:get($params, "extractMetadata"), map:get($params, "extractContent"), $applyTransform, $respondWithContent)
                        else store:updateDocumentContent($uri, $bodyContent, $contentType, $applyTransform, $respondWithContent)
                    else (),
                    if(exists($properties))
                    then store:setProperties($uri, $properties)
                    else (
                        store:addProperties($uri, $addProperties),
                        store:removeProperties($uri, $removeProperties)
                    ),
                    if(exists($permissions))
                    then store:setPermissions($uri, $permissions)
                    else (
                        store:addPermissions($uri, $addPermisssions),
                        store:removePermissions($uri, $removePermissions)
                    ),
                    if(exists($collections))
                    then store:setCollections($uri, $collections)
                    else (
                        store:addCollections($uri, $addCollections),
                        store:removeCollections($uri, $removeCollections)
                    ),
                    store:setQuality($uri, $quality)
                )
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }
        else common:error("corona:INVALID-PARAMETER", "Unknown request", $outputFormat)
    return
        if($requestMethod = "GET" and $output instance of binary())
        then common:output($output, store:getBinaryContentType($output))
        else common:output($output)
