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

import module namespace reststore="http://marklogic.com/reststore" at "lib/reststore.xqy";
import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";
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

let $params := rest:process-request(endpoints:request("/data/store.xqy"))
let $contentType := map:get($params, "content-type")
let $uri := map:get($params, "uri")
let $requestMethod := xdmp:get-request-method()
let $bodyContent := xdmp:get-request-body("text")/text()

let $collections := local:collectionsFromRequest($params, "collection")
let $properties := local:propertiesFromRequest($params, "property")
let $permissions := local:permissionsFromRequest($params, "permission")
let $quality := local:qualityFromRequest($params)

where exists($uri)
return
    if($contentType = "json")
    then
        if($requestMethod = "GET")
        then reststore:getJSONDocument($uri)
        else if($requestMethod = "DELETE")
        then reststore:deleteJSONDocument($uri)
        else if($requestMethod = "PUT")
        then reststore:insertJSONDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
        else if($requestMethod = "POST")
        then
            if(empty(doc($uri)) and exists($bodyContent))
            then reststore:insertJSONDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
            else (
                if(exists($bodyContent))
                then reststore:updateJSONDocumentContent($uri, $bodyContent)
                else (),
                local:syncMetadata($uri, $params)
            )
        else ()
    else if($contentType = "xml")
    then
        if($requestMethod = "GET")
        then reststore:getXMLDocument($uri)
        else if($requestMethod = "DELETE")
        then reststore:deleteXMLDocument($uri)
        else if($requestMethod = "PUT")
        then reststore:insertXMLDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
        else if($requestMethod = "POST")
        then
            if(empty(doc($uri)) and exists($bodyContent))
            then reststore:insertXMLDocument($uri, $bodyContent, $collections, $properties, $permissions, $quality)
            else (
                if(exists($bodyContent))
                then reststore:updateXMLDocumentContent($uri, $bodyContent)
                else (),
                local:syncMetadata($uri, $params)
            )
        else ()
    else ()
