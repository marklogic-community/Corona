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

module namespace reststore="http://marklogic.com/reststore";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "common.xqy";

(:
    Functions to retrieve request information
:)

declare function reststore:permissionsFromRequest(
) as element()*
{
    for $permission in xdmp:get-request-field("permission", ())
    let $bits := tokenize($permission, ":")
    let $user := string-join($bits[1 to last() - 1], ":")
    let $access := $bits[last()]
    where exists($user) and $access = ("update", "read", "execute")
    return xdmp:permission($user, $access)
};

declare function reststore:propertiesFromRequest(
) as element()*
{
    for $property in xdmp:get-request-field("property", ())
    let $bits := tokenize($property, ":")
    let $name := $bits[1]
    let $value := string-join($bits[2 to last()], ":")
    where exists($name)
    return element { QName("http://marklogic.com/reststore", $name) } { $value }
};

declare function reststore:collectionsFromRequest(
) as xs:string*
{
    xdmp:get-request-field("collection", ())
};

declare function reststore:qualityFromRequest(
) as xs:integer?
{
    let $quality := xdmp:get-request-field("quality", ())[1]
    return
        if($quality castable as xs:integer)
        then xs:integer($quality)
        else ()
};

(:
    Document management
:)

declare function reststore:getDocument(
    $uri as xs:string
)
{
    let $includes := xdmp:get-request-field("include", "content")
    let $content := $includes = ("content", "all")
    let $collections := $includes = ("collections", "all")
    let $properties := $includes = ("properties", "all")
    let $permissions := $includes = ("permissions", "all")
    let $quality := $includes = ("quality", "all")
    return reststore:getDocument($uri, $content, $collections, $properties, $permissions, $quality)
};

declare function reststore:getDocument(
    $uri as xs:string,
    $includeContent as xs:boolean,
    $includeCollections as xs:boolean,
    $includeProperties as xs:boolean,
    $includePermissions as xs:boolean,
    $includeQuality as xs:boolean
) as xs:string
{
    if(empty(doc($uri)))
    then common:error(404, "Document not found")
    else

    if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
    then json:xmlToJSON(doc($uri)/*)
    else json:xmlToJSON(json:document(
        json:object((
            if($includeContent)
            then ("content", doc($uri)/json:json)
            else (),
            if($includeCollections)
            then ("collections", reststore:getDocumentCollections($uri))
            else (),
            if($includeProperties)
            then ("properties", reststore:getDocumentProperties($uri))
            else (),
            if($includePermissions)
            then ("permissions", reststore:getDocumentPermissions($uri))
            else (),
            if($includeQuality)
            then ("quality", reststore:getDocumentQuality($uri))
            else ()
        ))
    ))
};

declare function reststore:insertDocument(
    $uri as xs:string,
    $content as xs:string
) as xs:string?
{
    let $collections := reststore:collectionsFromRequest()
    let $properties := reststore:propertiesFromRequest()
    let $permissions := reststore:permissionsFromRequest()
    let $quality := reststore:qualityFromRequest()
    return reststore:insertDocument($uri, $content, $collections, $properties, $permissions, $quality)
};

declare function reststore:insertDocument(
    $uri as xs:string,
    $content as xs:string,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element()*,
    $quality as xs:integer?
) as xs:string?
{
    let $body := try {
            json:jsonToXML($content)
        }
        catch ($e) {
            common:error(500, "Invalid JSON"),
            xdmp:log($e)
        }
    return (
        xdmp:document-insert($uri, $body, $permissions, $collections, $quality),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else ()
    )
};

declare function reststore:deleteDocument(
    $uri as xs:string
) as xs:string?
{
    if(exists(doc($uri)))
    then xdmp:document-delete($uri)
    else common:error(404, "Document not found")
};

declare function reststore:setProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    if(exists($properties))
    then xdmp:document-set-properties($uri, $properties)
    else ()
};

declare function reststore:setPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    if(exists($permissions))
    then xdmp:document-set-permissions($uri, $permissions)
    else ()
};

declare function reststore:setCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    if(exists($collections))
    then xdmp:document-set-collections($uri, $collections)
    else ()
};

declare function reststore:setQuality(
    $uri as xs:string,
    $quality as xs:integer?
) as empty-sequence()
{
    if(exists($quality))
    then xdmp:document-set-quality($uri, $quality)
    else ()
};




declare function reststore:getDocumentCollections(
    $uri as xs:string
) as element(json:item)
{
    json:array(
        for $collection in xdmp:document-get-collections($uri)
        return $collection
    )
};

declare function reststore:getDocumentProperties(
    $uri as xs:string
) as element(json:item)
{
    json:object(
        for $property in xdmp:document-properties($uri)/prop:properties/*
        where namespace-uri($property) = "http://marklogic.com/reststore"
        return (local-name($property), string($property))
    )
};

declare function reststore:getDocumentPermissions(
    $uri as xs:string
) as element(json:item)
{
    json:array(
        let $permMap := map:map()
        let $populate :=
            for $permission in xdmp:document-get-permissions($uri)
            let $role := string($permission/sec:role-id)
            let $capabilities := (map:get($permMap, $role), string($permission/sec:capability))
            return map:put($permMap, $role, $capabilities)
        for $key in map:keys($permMap)
        let $role := xdmp:eval("
                xquery version ""1.0-ml"";
                import module ""http://marklogic.com/xdmp/security"" at ""/MarkLogic/security.xqy"";
                declare variable $roleId as xs:unsignedLong external;
                sec:get-role-names($roleId)
            ", (
                xs:QName("roleId"), xs:unsignedLong($key)
            ), <options xmlns="xdmp:eval"><database>{ xdmp:security-database() }</database></options>)
        return json:object((
            $role, json:array(map:get($permMap, $key))
        ))
    )
};

declare function reststore:getDocumentQuality(
    $uri as xs:string
) as xs:decimal
{
    xdmp:document-get-quality($uri)
};
