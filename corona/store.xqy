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
import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";

import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "lib/date-parser.xqy";

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
    let $date := dateparser:parse($value)
    let $dateAttribute := if(exists($date)) then attribute normalized-date { $date } else ()
    where exists($name)
    return element { QName("http://marklogic.com/reststore", $name) } { ($dateAttribute, $value) }
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
    return
        if($quality castable as xs:integer)
        then xs:integer($quality)
        else ()
};

declare function local:syncMetadata(
    $uri as xs:string,
    $params as map:map
) as empty-sequence()
{
    let $collections := local:collectionsFromRequest($params, "collection")
    let $properties := local:propertiesFromRequest($params, "property")
    let $permissions := local:permissionsFromRequest($params, "permission")
    let $quality := local:qualityFromRequest($params)

    let $addCollections := local:collectionsFromRequest($params, "addCollection")
    let $addProperties := local:propertiesFromRequest($params, "addProperty")
    let $addPermisssions := local:permissionsFromRequest($params, "addPermission")

    let $removeCollections := local:collectionsFromRequest($params, "removeCollection")
    let $removeProperties := map:get($params, "removeProperty")
    let $removePermissions := local:permissionsFromRequest($params, "removePermission")

    return (
        if(exists($properties))
        then reststore:setProperties($uri, $properties)
        else (
            reststore:addProperties($uri, $addProperties),
            reststore:removeProperties($uri, $removeProperties)
        ),
        if(exists($permissions))
        then reststore:setPermissions($uri, $permissions)
        else (
            reststore:addPermissions($uri, $addPermisssions),
            reststore:removePermissions($uri, $removePermissions)
        ),
        if(exists($collections))
        then reststore:setCollections($uri, $collections)
        else (
            reststore:addCollections($uri, $addCollections),
            reststore:removeCollections($uri, $removeCollections)
        ),
        reststore:setQuality($uri, $quality)
    )
};

let $requestMethod := xdmp:get-request-method()
let $bodyContent := xdmp:get-request-body("text")/text()
let $params := rest:process-request(endpoints:request("/corona/store.xqy"))
let $contentType := map:get($params, "content-type")
let $uri := map:get($params, "uri")
let $include := map:get($params, "include")
let $extractPath := map:get($params, "extractPath")
let $transformer := map:get($params, "applyTransformer")

let $tests := (
    if($requestMethod = ("PUT", "POST", "GET") and string-length($uri) = 0)
    then common:error(400, "corona:INVALID-PARAMETER", "Must supply a URI when inserting, updating or fetching a document", $contentType)
    else ()
)

let $collections := local:collectionsFromRequest($params, "collection")
let $properties := local:propertiesFromRequest($params, "property")
let $quality := local:qualityFromRequest($params)
let $permissions :=
    try {
        local:permissionsFromRequest($params, "permission")
    }
    catch ($e) {
        if($e/*:code = "SEC-ROLEDNE")
        then xdmp:set($tests, common:error(400, "corona:INVALID-PERMISSION", concat("The role '", $e/*:data/*:datum[. != "sec:role-name"], "' does not exist."), $contentType))
        else common:errorFromException(500, $e, $contentType)
    }

let $structuredQuery :=
    try {
        structquery:getParseTree(map:get($params, "structuredQuery"))
    }
    catch ($e) {
        xdmp:set($tests, common:error(400, "corona:INVALID-PARAMETER", concat("The structured query JSON isn't valid: ", $e/*:message), $contentType))
    }

let $query := (stringquery:parse(map:get($params, "q")), structquery:getCTS($structuredQuery))[1]

let $log := xdmp:log(concat(":", $uri, ":"))
where string-length($uri) or ($requestMethod = "DELETE" and exists($query)) or exists($tests)
return
    if(exists($tests))
    then $tests
    else

    if($contentType = "json")
    then
        if($requestMethod = "GET" and string-length($uri))
        then try {
            reststore:getJSONDocument($uri, $include, $extractPath, $transformer, $query)
        }
        catch ($e) {
            common:errorFromException(400, $e, $contentType)
        }
        else if($requestMethod = "DELETE")
        then
            if(string-length($uri))
            then reststore:deleteJSONDocument($uri, map:get($params, "include") = ("uri", "uris"))
            else if(exists($query))
            then reststore:deleteJSONDocumentsWithQuery($query, map:get($params, "bulkDelete"), map:get($params, "include") = ("uri", "uris"), map:get($params, "limit"))
            else common:error(400, "corona:MISSING-PARAMETER", "Missing parameters: must specify a URI, a string query or a structured query with DELETE requests", $contentType)
        else if($requestMethod = "PUT" and string-length($uri))
        then reststore:insertJSONDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
        else if($requestMethod = "POST" and string-length($uri))
        then
            if(empty(doc($uri)) and exists($bodyContent))
            then reststore:insertJSONDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
            else
                let $docError :=
                    if(exists($bodyContent))
                    then reststore:updateJSONDocumentContent($uri, $bodyContent)
                    else ()
                return
                    if($docError)
                    then $docError
                    else try {
                        local:syncMetadata($uri, $params)
                    }
                    catch ($e) {
                        xdmp:log($e)
                    }
        else common:error(400, "corona:INVALID-PARAMETER", "Unknown request", $contentType)
    else if($contentType = "xml")
    then
        if($requestMethod = "GET" and string-length($uri))
        then try {
            reststore:getXMLDocument($uri, $include, $extractPath, $transformer, $query)
        }
        catch ($e) {
            common:errorFromException(400, $e, $contentType)
        }
        else if($requestMethod = "DELETE")
        then
            if(string-length($uri))
            then reststore:deleteXMLDocument($uri, map:get($params, "include") = ("uri", "uris"))
            else if(exists($query))
            then reststore:deleteXMLDocumentsWithQuery($query, map:get($params, "bulkDelete"), map:get($params, "include") = ("uri", "uris"), map:get($params, "limit"))
            else common:error(400, "corona:MISSING-PARAMETER", "Missing parameters: must specify a URI, a string query or a structured query with DELETE requests", $contentType)
        else if($requestMethod = "PUT" and string-length($uri))
        then reststore:insertXMLDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
        else if($requestMethod = "POST" and string-length($uri))
        then
            if(empty(doc($uri)) and exists($bodyContent))
            then reststore:insertXMLDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
            else
                let $docError :=
                    if(exists($bodyContent))
                    then reststore:updateXMLDocumentContent($uri, $bodyContent)
                    else ()
                return
                    if($docError)
                    then $docError
                    else try {
                        local:syncMetadata($uri, $params)
                    }
                    catch ($e) {
                        xdmp:log($e)
                    }
        else common:error(400, "corona:INVALID-PARAMETER", "Unknown request", $contentType)
    else ()
