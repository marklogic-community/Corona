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
import module namespace manage="http://marklogic.com/mljson/manage" at "manage.xqy";

import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

(:
    JSON Document management
:)

declare function reststore:getJSONDocument(
    $uri as xs:string,
    $include as xs:string*,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $highlightQuery as cts:query?
) as xs:string
{
    if(empty(doc($uri)/json:json))
    then common:error(404, "Document not found", "json")
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")
    let $content :=
        if(exists($extractPath))
        then path:select(root(doc($uri)/json:json), $extractPath)
        else root(doc($uri)/json:json)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then reststore:highlightJSONContent($content, $highlightQuery)
        else $content
    let $content :=
        if(exists($applyTransform))
        then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
        else $content
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then json:xmlToJSON($content)
        else json:xmlToJSON(json:document(
            json:object(reststore:outputJSONDocument($uri, $content, $include))
        ))
};

declare function reststore:outputMultipleJSONDocs(
    $docs as element(json:json)*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?,
    $extractPath as xs:string?,
    $applyTransform as xs:string?
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
                    if(exists($extractPath))
                    then path:select($doc, $extractPath)
                    else $doc
                let $content :=
                    if($include = ("highlighting") and exists($query))
                    then reststore:highlightJSONContent($content, $query)
                    else $content
                let $content :=
                    if(exists($applyTransform))
                    then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
                    else $content
                return json:object((
                    "uri", $uri,
                    reststore:outputJSONDocument($uri, $content, $include),
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
    $content as node()?,
    $include as xs:string*
)
{
    if($include = ("content", "all"))
    then ("content", $content)
    else (),
    if($include = ("collections", "all"))
    then ("collections", reststore:getDocumentCollections($uri, "json"))
    else (),
    if($include = ("properties", "all"))
    then ("properties", reststore:getDocumentProperties($uri, "json"))
    else (),
    if($include = ("permissions", "all"))
    then ("permissions", reststore:getDocumentPermissions($uri, "json"))
    else (),
    if($include = ("quality", "all"))
    then ("quality", reststore:getDocumentQuality($uri))
    else ()
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
            common:error(400, "Invalid JSON", "json"),
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
            common:error(400, "Invalid JSON", "json"),
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
    $uri as xs:string,
    $include as xs:string*,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $highlightQuery as cts:query?
) as item()
{
    if(empty(reststore:getRawXMLDoc($uri)))
    then common:error(404, "Document not found", "xml")
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")
    let $content :=
        if(exists($extractPath))
        then reststore:getRawXMLDoc($uri)/xdmp:value($extractPath)
        else reststore:getRawXMLDoc($uri)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then reststore:highlightXMLContent($content, $highlightQuery)
        else $content
    let $content :=
        if(exists($applyTransform))
        then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
        else $content
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then $content
        else 
            <response>{
                reststore:outputXMLDocument($uri, $content, $include)
            }</response>
};

declare function reststore:outputMultipleXMLDocs(
    $docs as element()*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?,
    $extractPath as xs:string?,
    $applyTransform as xs:string?
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
                    if(exists($extractPath))
                    then root($doc)/xdmp:value($extractPath)
                    else $doc
                let $content :=
                    if($include = ("highlighting") and exists($query))
                    then reststore:highlightXMLContent($content, $query)
                    else $content
                let $content :=
                    if(exists($applyTransform))
                    then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
                    else $content
                return <result>{(
                    <uri>{ $uri }</uri>,
                    reststore:outputXMLDocument($uri, $content, $include),
                    if($include = ("snippet", "all"))
                    then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*)))
                    else ()
                )}</result>
            }</results>
        </response>
};

declare private function reststore:outputXMLDocument(
    $uri as xs:string,
    $content as node()?,
    $include as xs:string*
) as element()*
{
    if($include = ("content", "all"))
    then <content>{ $content }</content>
    else (),
    if($include = ("collections", "all"))
    then <collections>{ reststore:getDocumentCollections($uri, "xml") }</collections>
    else (),
    if($include = ("properties", "all"))
    then <properties>{ reststore:getDocumentProperties($uri, "xml") }</properties>
    else (),
    if($include = ("permissions", "all"))
    then <permissions>{ reststore:getDocumentPermissions($uri, "xml") }</permissions>
    else (),
    if($include = ("quality", "all"))
    then <quality>{ reststore:getDocumentQuality($uri) }</quality>
    else ()
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
            common:error(400, "Invalid XML", "xml"),
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
            common:error(400, "Invalid XML", "xml"),
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
) as node()?
{
    let $doc := doc($uri)
    where xdmp:document-get-collections($uri) = $const:XMLCollection
    return $doc
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

declare function reststore:addProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    xdmp:document-add-properties($uri, $properties)
};

declare function reststore:removeProperties(
    $uri as xs:string,
    $properties as xs:string*
) as empty-sequence()
{
    let $properties :=
        for $prop in $properties
        return QName("http://marklogic.com/reststore", $prop)
    return xdmp:document-remove-properties($uri, $properties)
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

declare function reststore:addPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    xdmp:document-add-permissions($uri, $permissions)
};

declare function reststore:removePermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    xdmp:document-remove-permissions($uri, $permissions)
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

declare function reststore:addCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    xdmp:document-add-collections($uri, $collections)
};

declare function reststore:removeCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    xdmp:document-remove-collections($uri, $collections)
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

declare private function reststore:highlightJSONContent(
    $content as node(),
    $query as cts:query
) as node()
{
    cts:highlight($content, $query, concat('<span class="hit">', $cts:text, '</span>'))
};

declare private function reststore:highlightXMLContent(
    $content as node(),
    $query as cts:query
) as node()
{
    xdmp:log($query),
    cts:highlight($content, $query, <span class="hit">{ $cts:text }</span>)
};
