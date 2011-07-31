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
import module namespace path="http://marklogic.com/mljson/path-parser" at "path-parser.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "common.xqy";
import module namespace const="http://marklogic.com/mljson/constants" at "constants.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

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
    JSON Document management
:)

declare function reststore:getJSONDocument(
    $uri as xs:string
) as xs:string
{
    reststore:getJSONDocument($uri, xdmp:get-request-field("include", "content"))
};

declare function reststore:getJSONDocument(
    $uri as xs:string,
    $includes as xs:string*
) as xs:string
{
    if(empty(doc($uri)/json:json))
    then common:error(404, "Document not found", "json")
    else

    let $includeContent := $includes = ("content", "all")
    let $includeCollections := $includes = ("collections", "all")
    let $includeProperties := $includes = ("properties", "all")
    let $includePermissions := $includes = ("permissions", "all")
    let $includeQuality := $includes = ("quality", "all")
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then json:xmlToJSON(doc($uri)/json:json)
        else json:xmlToJSON(json:document(
            json:object(reststore:outputJSONDocument($uri, doc($uri)/json:json, $includeContent, $includeCollections, $includeProperties, $includePermissions, $includeQuality))
        ))
};

declare function reststore:outputMultipleJSONDocs(
    $docs as element(json:json)*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?,
    $returnPath as xs:string?
) as xs:string
{
    let $end :=
        if(empty($end))
        then $start
        else $end

    return json:xmlToJSON(
        json:object((
            "meta", json:object((
                "start", $start,
                "end", $end,
                "total", $total
            )),
            "results", json:array(
                for $doc in $docs
                let $uri := base-uri($doc)
                let $content :=
                    if(exists($returnPath))
                    then path:select($doc, $returnPath)
                    else $doc
                return json:object((
                    "uri", $uri,
                    reststore:outputJSONDocument($uri, $content, $include = ("content", "all"), $include = ("collections", "all"), $include = ("properties", "all"), $include = ("permissions", "all"), $include = ("quality", "all")),
                    if($include = ("snippet", "all"))
                    then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*)))
                    else ()
                ))
            )
        ))
    )
};

declare private function reststore:outputJSONDocument(
    $uri as xs:string,
    $content as element()?,
    $includeContent as xs:boolean,
    $includeCollections as xs:boolean,
    $includeProperties as xs:boolean,
    $includePermissions as xs:boolean,
    $includeQuality as xs:boolean
)
{
    if($includeContent)
    then ("content", doc($uri)/json:json)
    else (),
    if($includeCollections)
    then ("collections", reststore:getDocumentCollections($uri, "json"))
    else (),
    if($includeProperties)
    then ("properties", reststore:getDocumentProperties($uri, "json"))
    else (),
    if($includePermissions)
    then ("permissions", reststore:getDocumentPermissions($uri, "json"))
    else (),
    if($includeQuality)
    then ("quality", reststore:getDocumentQuality($uri))
    else ()
};

declare function reststore:insertJSONDocument(
    $uri as xs:string,
    $content as xs:string
) as xs:string?
{
    let $collections := reststore:collectionsFromRequest()
    let $properties := reststore:propertiesFromRequest()
    let $permissions := reststore:permissionsFromRequest()
    let $quality := reststore:qualityFromRequest()
    return reststore:insertJSONDocument($uri, $content, $collections, $properties, $permissions, $quality)
};

declare function reststore:insertJSONDocument(
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
            common:error(500, "Invalid JSON", "json"),
            xdmp:log($e)
        }
    return (
        xdmp:document-insert($uri, $body, $permissions, ($const:JSONCollection, $collections), $quality),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else ()
    )
};

declare function reststore:updateJSONDocumentContent(
    $uri as xs:string,
    $content as xs:string
) as xs:string?
{
    let $body := try {
            json:jsonToXML($content)
        }
        catch ($e) {
            common:error(500, "Invalid JSON", "json"),
            xdmp:log($e)
        }
    let $existing := doc($uri)/json:json
    let $test :=
        if(empty($existing))
        then common:error(404, concat("There is no JSON document to update at '", $uri, "'"), "json")
        else ()
    where exists($existing)
    return xdmp:node-replace($existing, $body)
};

declare function reststore:deleteJSONDocument(
    $uri as xs:string
) as xs:string?
{
    if(exists(doc($uri)/json:json))
    then xdmp:document-delete($uri)
    else common:error(404, concat("There is no JSON document to delete at '", $uri, "'"), "json")
};


(:
    XML Document management
:)

declare function reststore:getXMLDocument(
    $uri as xs:string
) as element()
{
    reststore:getXMLDocument($uri, xdmp:get-request-field("include", "content"))
};

declare function reststore:getXMLDocument(
    $uri as xs:string,
    $includes as xs:string*
) as element()
{
    if(empty(reststore:getRawXMLDoc($uri)))
    then common:error(404, "Document not found", "xml")
    else

    let $includeContent := $includes = ("content", "all")
    let $includeCollections := $includes = ("collections", "all")
    let $includeProperties := $includes = ("properties", "all")
    let $includePermissions := $includes = ("permissions", "all")
    let $includeQuality := $includes = ("quality", "all")
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then reststore:getRawXMLDoc($uri)
        else 
            (: XXX - Will need to output in a real XML format :)
            <response>{
                reststore:outputXMLDocument($uri, reststore:getRawXMLDoc($uri), $includeContent, $includeCollections, $includeProperties, $includePermissions, $includeQuality)
            }</response>
};

declare function reststore:outputMultipleXMLDocs(
    $docs as element()*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?,
    $returnPath as xs:string?
) as element()
{
    let $end :=
        if(empty($end))
        then $start
        else $end
    return 
        <response>
            <meta>
                <start>{ $start }</start>
                <end>{ $end }</end>
                <total>{ $total }</total>
            </meta>
            <results>{
                for $doc in $docs
                let $uri := base-uri($doc)
                let $content :=
                    if(exists($returnPath))
                    then path:select($doc, $returnPath)
                    else $doc
                return <result>{(
                    <uri>{ $uri }</uri>,
                    reststore:outputXMLDocument($uri, $content, $include = ("content", "all"), $include = ("collections", "all"), $include = ("properties", "all"), $include = ("permissions", "all"), $include = ("quality", "all")),
                    if($include = ("snippet", "all"))
                    then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*)))
                    else ()
                )}</result>
            }</results>
        </response>
};

declare private function reststore:outputXMLDocument(
    $uri as xs:string,
    $content as element()?,
    $includeContent as xs:boolean,
    $includeCollections as xs:boolean,
    $includeProperties as xs:boolean,
    $includePermissions as xs:boolean,
    $includeQuality as xs:boolean
) as element()*
{
    if($includeContent)
    then <content>{ $content }</content>
    else (),
    if($includeCollections)
    then <collections>{ reststore:getDocumentCollections($uri, "xml") }</collections>
    else (),
    if($includeProperties)
    then <properties>{ reststore:getDocumentProperties($uri, "xml") }</properties>
    else (),
    if($includePermissions)
    then <permissions>{ reststore:getDocumentPermissions($uri, "xml") }</permissions>
    else (),
    if($includeQuality)
    then <quality>{ reststore:getDocumentQuality($uri) }</quality>
    else ()
};

declare function reststore:insertXMLDocument(
    $uri as xs:string,
    $content as xs:string
) as element()?
{
    let $collections := reststore:collectionsFromRequest()
    let $properties := reststore:propertiesFromRequest()
    let $permissions := reststore:permissionsFromRequest()
    let $quality := reststore:qualityFromRequest()
    return reststore:insertXMLDocument($uri, $content, $collections, $properties, $permissions, $quality)
};

declare function reststore:insertXMLDocument(
    $uri as xs:string,
    $content as xs:string,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element()*,
    $quality as xs:integer?
) as element()?
{
    let $body := try {
            xdmp:unquote($content, (), ("repair-none", "format-xml"))[1]
        }
        catch ($e) {
            common:error(500, "Invalid XML", "xml"),
            xdmp:log($e)
        }
    return (
        xdmp:document-insert($uri, $body, $permissions, ($const:XMLCollection, $collections), $quality),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else ()
    )
};

declare function reststore:updateXMLDocumentContent(
    $uri as xs:string,
    $content as xs:string
) as element()?
{
    let $body := try {
            xdmp:unquote($content, (), ("repair-none", "format-xml"))[1]
        }
        catch ($e) {
            common:error(500, "Invalid XML", "xml"),
            xdmp:log($e)
        }
    let $existing := reststore:getRawXMLDoc($uri)
    let $test :=
        if(empty($existing))
        then common:error(404, concat("There is no XML document to update at '", $uri, "'"), "xml")
        else ()
    where exists($existing)
    return xdmp:node-replace($existing, $body)
};

declare function reststore:deleteXMLDocument(
    $uri as xs:string
) as element()?
{
    if(exists(reststore:getRawXMLDoc($uri)))
    then xdmp:document-delete($uri)
    else common:error(404, concat("There is no XML document to delete at '", $uri, "'"), "xml")
};

declare function reststore:getRawXMLDoc(
    $uri as xs:string
) as element()?
{
    let $doc := doc($uri)
    let $log := xdmp:log($doc)
    where xdmp:document-get-collections($uri) = $const:XMLCollection
    return $doc/*
};


(:
    Functions to manage document metadata
:)

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
    let $doc := doc($uri)
    where exists($doc) and exists($collections)
    return
        if(exists($doc/json:json))
        then xdmp:document-set-collections($uri, ($const:JSONCollection, $collections))
        else xdmp:document-set-collections($uri, ($const:XMLCollection, $collections))
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




declare private function reststore:getDocumentCollections(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    if($outputFormat = "json")
    then json:array(xdmp:document-get-collections($uri)[not(. = ($const:JSONCollection, $const:XMLCollection))])
    else
        for $collection in xdmp:document-get-collections($uri)
        where not($collection = ($const:JSONCollection, $const:XMLCollection))
        return <collection>{ $collection }</collection>
};

declare private function reststore:getDocumentProperties(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    if($outputFormat = "json")
    then
        json:object(
            for $property in xdmp:document-properties($uri)/prop:properties/*
            where namespace-uri($property) = "http://marklogic.com/reststore"
            return (local-name($property), string($property))
        )
    else
        for $property in xdmp:document-properties($uri)/prop:properties/*
        where namespace-uri($property) = "http://marklogic.com/reststore"
        return element { local-name($property) } { string($property) }
};

declare private function reststore:getDocumentPermissions(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    if($outputFormat = "json")
    then
        json:object(
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
            return (
                $role, json:array(map:get($permMap, $key))
            )
        )
    else
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
        return element { $role } { for $perm in map:get($permMap, $key) return <permission>{ $perm }</permission> }
};

declare private function reststore:getDocumentQuality(
    $uri as xs:string
) as xs:decimal
{
    xdmp:document-get-quality($uri)
};
