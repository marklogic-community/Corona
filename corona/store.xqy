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
import module namespace stringquery="http://marklogic.com/corona/string-query" at "lib/string-query.xqy";
import module namespace structquery="http://marklogic.com/corona/structured-query" at "lib/structured-query.xqy";
import module namespace store="http://marklogic.com/corona/store" at "lib/store.xqy";
import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";

import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";

declare option xdmp:mapping "false";

declare function local:collectionsFromRequest(
    $params as map:map,
    $type as xs:string
) as xs:string*
{
    map:get($params, $type)
};

declare function local:propertiesFromRequest(
    $params as map:map,
    $type as xs:string
) as element()*
{
    for $property in map:get($params, $type)
    let $bits := tokenize($property, ":")
    let $name := $bits[1]
    let $value := string-join($bits[2 to last()], ":")
    where exists($name)
    return store:createProperty($name, $value)
};

declare function local:permissionsFromRequest(
    $params as map:map,
    $type as xs:string
) as element()*
{
    for $permission in map:get($params, $type)
    let $bits := tokenize($permission, ":")
    let $user := string-join($bits[1 to last() - 1], ":")
    let $access := $bits[last()]
    where exists($user) and $access = ("update", "read", "execute")
    return xdmp:permission($user, $access)
};

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
        let $include := map:get($params, "include")
        let $extractPath := map:get($params, "extractPath")
        let $transformer := map:get($params, "applyTransform")
        return store:getDocument($uri, $include, $extractPath, $transformer, local:queryFromRequest($params), $outputFormat)
    }
    catch ($e) {
        common:errorFromException($e, $outputFormat)
    }

    else if($requestMethod = "PUT" and string-length($uri))
    then try {
        let $bodyContent := xdmp:get-request-body("text")/text()
        let $collections := local:collectionsFromRequest($params, "collection")
        let $properties := local:propertiesFromRequest($params, "property")
        let $permissions := local:permissionsFromRequest($params, "permission")
        let $quality := local:qualityFromRequest($params)
        let $contentType := common:getContentType($uri, map:get($params, "contentType"))
        let $set := xdmp:set-response-code(204, "Document inserted")
        return store:insertDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality, $contentType)
    }
    catch ($e) {
        common:errorFromException($e, $outputFormat)
    }

    else if($requestMethod = "POST" and string-length($uri))
    then try {
        let $bodyContent := xdmp:get-request-body("text")/text()
        let $collections := local:collectionsFromRequest($params, "collection")
        let $properties := local:propertiesFromRequest($params, "property")
        let $permissions := local:permissionsFromRequest($params, "permission")
        let $quality := local:qualityFromRequest($params)
        let $contentType := common:getContentType($uri, map:get($params, "contentType"))

        let $addCollections := local:collectionsFromRequest($params, "addCollection")
        let $addProperties := local:propertiesFromRequest($params, "addProperty")
        let $addPermisssions := local:permissionsFromRequest($params, "addPermission")

        let $removeCollections := local:collectionsFromRequest($params, "removeCollection")
        let $removeProperties := map:get($params, "removeProperty")
        let $removePermissions := local:permissionsFromRequest($params, "removePermission")

        let $set := xdmp:set-response-code(204, "Document updated")
        return (
            if(empty(doc($uri)) and exists($bodyContent))
            then store:insertDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality, $contentType)
            else if(exists($bodyContent))
            then store:updateDocumentContent($uri, $bodyContent, $contentType)
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
