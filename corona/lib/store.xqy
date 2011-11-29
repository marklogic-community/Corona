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

module namespace store="http://marklogic.com/corona/store";

import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "path-parser.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "manage.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";

declare namespace corona="http://marklogic.com/corona";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $xsltEval := try { xdmp:function(xs:QName("xdmp:xslt-eval")) } catch ($e) {};
declare variable $xsltIsSupported := try { xdmp:apply($xsltEval, <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"/>, <foo/>)[3], true() } catch ($e) {xdmp:log($e), false() };

declare function store:outputMultipleDocuments(
    $docs as document-node()*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $outputFormat as xs:string
)
{
    let $start :=
        if($total = 0)
        then 0
        else $start
    let $end :=
        if(empty($end))
        then $start
        else $end

    let $results :=
        for $doc in $docs
        let $uri := base-uri($doc)
        let $collections := xdmp:document-get-collections($uri)
        let $contentType := store:getDocumentType($uri)
        let $pathType := if($contentType = "xml") then "xpath" else "json"

        (: Perform the path extraction if one was provided :)
        let $content :=
            if($contentType = "text")
            then $doc/text()
            else if(exists($extractPath))
            then store:wrapContentNodes(path:select(if($contentType = "json") then $doc/json:json else $doc, $extractPath, $pathType), $contentType)
            else $doc

        (: Highlight the content body :)
        let $content :=
            if($include = ("highlighting") and exists($query))
            then store:highlightContent($content, $query, $outputFormat)
            else $content

        (: Apply the transformation :)
        let $content :=
            if(exists($applyTransform))
            then store:applyTransformer($applyTransform, $content)
            else $content

        (: If the wrapper element from wrapContentNodes is still sticking around, remove it :)
        let $content :=
            if($contentType = "xml" and namespace-uri($content) = "http://marklogic.com/corona/store")
            then $content/*
            else $content

        let $snippet :=
            if($include = ("snippet", "all"))
            then common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*), $outputFormat)
            else ()

        where exists($contentType)
        return
            if($outputFormat = "json")
            then json:object((
                "uri", $uri,
                store:outputDocument($uri, $content, $include, $contentType, $outputFormat),
                if($include = ("snippet", "all"))
                then ("snippet", $snippet)
                else (),
                if($include = ("confidence", "all"))
                then ("confidence", cts:confidence($doc))
                else ()
            ))
            else if($outputFormat = "xml")
            then <corona:result>{(
                <corona:uri>{ $uri }</corona:uri>,
                store:outputDocument($uri, $content, $include, $contentType, $outputFormat),
                if($include = ("snippet", "all"))
                then <corona:snippet>{ $snippet }</corona:snippet>
                else (),
                if($include = ("confidence", "all"))
                then <corona:confidence>{ cts:confidence($doc) }</corona:confidence>
                else ()
            )}</corona:result>
            else ()

    let $executionTime := substring(string(xdmp:query-meters()/*:elapsed-time), 3, 4)
    return
        if($outputFormat = "json")
        then json:serialize(
            json:object((
                "meta", json:object((
                    "start", $start,
                    "end", $end,
                    "total", $total,
                    "executionTime", $executionTime
                )),
                if($include = "none") then () else ("results", json:array($results))
            ))
        )
        else if($outputFormat = "xml")
        then <corona:response>
                <corona:meta>
                    <corona:start>{ $start }</corona:start>
                    <corona:end>{ $end }</corona:end>
                    <corona:total>{ $total }</corona:total>
                    <corona:executionTime>{ $executionTime }</corona:executionTime>
                </corona:meta>
                { if($include = "none") then () else <corona:results>{ $results }</corona:results> }
            </corona:response>
        else ()
};

declare function store:moveDocument(
    $existingURI as xs:string,
    $newURI as xs:string
) as empty-sequence()
{
    let $test :=
        if(empty(doc($existingURI)))
        then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document to move at '", $existingURI, "'"))
        else ()
    let $test :=
        if(exists(doc($newURI)))
        then error(xs:QName("corona:DOCUMENT-EXISTS"), concat("There is already a document at '", $newURI, "'"))
        else ()
    return (
        xdmp:document-insert($newURI, doc($existingURI), xdmp:document-get-permissions($existingURI), xdmp:document-get-collections($existingURI), xdmp:document-get-quality($existingURI)),
        xdmp:document-set-properties($newURI, xdmp:document-properties($existingURI)/prop:properties/*),
        xdmp:document-delete($existingURI)
    )
};

declare function store:documentExists(
    $uri as xs:string
) as xs:boolean
{
    exists(doc($uri))
};

declare function store:getDocumentType(
    $uri as xs:string
) as xs:string?
{
    let $doc := doc($uri)
    return
        if(exists($doc/json:json))
        then "json"
        else if(exists($doc/*))
        then "xml"
        else if(exists($doc/text()))
        then "text"
        else if(exists($doc/binary()))
        then "binary"
        else ()
};

declare function store:deleteDocument(
    $uri as xs:string,
    $includeURIs as xs:boolean,
    $outputFormat as xs:string
)
{
    if(store:documentExists($uri))
    then (
        if(store:getDocumentType($uri) = "binary" and exists(doc(store:getSidecarURI($uri))))
        then xdmp:document-delete(store:getSidecarURI($uri))
        else (),
        xdmp:document-delete($uri),
        if($outputFormat = "json")
        then json:serialize(json:object((
            "meta", json:object((
                "deleted", 1,
                "numRemaining", 0
            )),
            if($includeURIs)
            then ("uris", json:array($uri))
            else ()
        )))
        else if($outputFormat = "xml")
        then <corona:results>
            <corona:meta>
                <corona:deleted>1</corona:deleted>
                <corona:numRemaining>0</corona:numRemaining>
            </corona:meta>
            {
                if($includeURIs)
                then <corona:uris><corona:uri>{ $uri }</corona:uri></corona:uris>
                else ()
            }
        </corona:results>
        else ()
    )
    else error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document to delete at '", $uri, "'"))
};

declare function store:deleteDocumentsWithQuery(
    $query as cts:query,
    $bulkDelete as xs:boolean,
    $includeURIs as xs:boolean,
    $limit as xs:integer?,
    $outputFormat as xs:string
)
{
    let $docs :=
        if(exists($limit))
        then cts:search(doc(), $query)[1 to $limit]
        else cts:search(doc(), $query)
    let $count := if(exists($docs)) then cts:remainder($docs[1]) else 0
    let $numDeleted :=
        if(exists($limit))
        then $limit
        else $count
    let $deletedURIs :=
        for $doc in $docs
        let $uri := base-uri($doc)
        where not(xdmp:document-get-collections($uri) = $const:TransformersCollection)
        return (
            if(exists(doc($doc/corona:sidecar/@original)))
            then (string($doc/corona:sidecar/@original), xdmp:document-delete($doc/corona:sidecar/@original))
            else $uri
            ,
            xdmp:document-delete($uri)
        )
    return
        if($bulkDelete or $count = 1)
        then
            if($outputFormat = "json")
            then json:serialize(json:object((
                "meta", json:object((
                    "deleted", $numDeleted,
                    "numRemaining", $count - $numDeleted
                )),
                if($includeURIs)
                then ("uris", json:array($deletedURIs))
                else ()
            )))
            else if($outputFormat = "xml")
            then <corona:results>
                <corona:meta>
                    <corona:deleted>{ $numDeleted }</corona:deleted>
                    <corona:numRemaining>{ $count - $numDeleted }</corona:numRemaining>
                </corona:meta>
                {
                    if($includeURIs)
                    then <corona:uris>{
                        for $uri in $deletedURIs
                        return <corona:uri>{ $uri }</corona:uri>
                    }</corona:uris>
                    else ()
                }
            </corona:results>
            else ()
        else if($count = 0)
        then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), "DELETE query doesn't match any documents")
        else error(xs:QName("corona:REQUIRES-BULK-DELETE"), "DELETE query matches more than one document without enabling bulk deletes")
};

declare function store:getDocument(
    $uri as xs:string,
    $include as xs:string*,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $highlightQuery as cts:query?,
    $outputFormat as xs:string
)
{
    if(not(store:documentExists($uri)))
    then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("Document at '", $uri, "' not found"))
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")

    let $collections := xdmp:document-get-collections($uri)
    let $contentType := store:getDocumentType($uri)
    let $pathType := if($contentType = "xml") then "xpath" else "json"

    let $test :=
        if($contentType = "binary" and (($include = "content" and count($include) > 1) or $include = "all"))
        then error(xs:QName("corona:INVALID-PARAMETER"), "Can not include binary content along with it's metadata")
        else ()

    let $content :=
        if($contentType = "text")
        then doc($uri)/text()
        else if($contentType = "binary")
        then doc($uri)/binary()
        else if(exists($extractPath))
        then store:wrapContentNodes(path:select(doc($uri)/*, $extractPath, $pathType), $contentType)
        else doc($uri)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then store:highlightContent($content, $highlightQuery, $contentType)
        else $content
    let $content :=
        if(exists($applyTransform))
        then store:applyTransformer($applyTransform, $content)
        else $content
    let $content :=
        if(namespace-uri($content) = "http://marklogic.com/corona/store")
        then $content/*
        else $content
    let $uri :=
        if($contentType = "binary")
        then store:getSidecarURI($uri)
        else $uri
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then
            if($contentType = ("xml", "text", "binary"))
            then $content
            else json:serialize($content)
        else
            if($outputFormat = "xml")
            then <corona:response>{ store:outputDocument($uri, $content, $include, "xml", "xml") }</corona:response>
            else json:serialize(json:document(
                json:object(store:outputDocument($uri, $content, $include, "json", "json"))
            ))
};

declare function store:insertDocument(
    $uri as xs:string,
    $content as xs:string,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element()*,
    $quality as xs:integer?,
    $contentType as xs:string
) as empty-sequence()
{
    let $body :=
        if($contentType = "json")
        then json:parse($content)
        else if($contentType = "xml")
        then xdmp:unquote($content, (), ("repair-none", "format-xml"))[1]
        else if($contentType = "text")
        then text { $content }
        else error(xs:QName("corona:INVALID-PARAMETER"), "Invalid content type, must be one of xml, json or text")
    return (
        xdmp:document-insert($uri, $body, (xdmp:default-permissions(), $permissions), $collections, $quality),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else xdmp:document-set-properties($uri, ())
    )
};

declare function store:insertBinaryDocument(
    $uri as xs:string,
    $content as binary(),
    $suppliedContent as xs:string?,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element()*,
    $quality as xs:integer?
) as empty-sequence()
{
    let $suppliedContent :=
        if(exists($suppliedContent))
        then
            if(common:xmlOrJSON($suppliedContent) = "json")
            then json:parse($suppliedContent)
            else xdmp:unquote($suppliedContent, (), ("repair-none", "format-xml"))[1]
        else ()
    let $sidecarURI := store:getSidecarURI($uri)
    let $sidecar := <corona:sidecar type="binary">{ $suppliedContent }</corona:sidecar>
    let $insertSidecar := xdmp:document-insert($sidecarURI, $sidecar, (xdmp:default-permissions(), $permissions), $collections, $quality)
    let $setPropertis :=
        if(exists($properties))
        then xdmp:document-set-properties($sidecarURI, $properties)
        else xdmp:document-set-properties($sidecarURI, ())
    return xdmp:document-insert($uri, $content, (xdmp:default-permissions(), $permissions), $collections, $quality)
};

declare function store:updateDocumentContent(
    $uri as xs:string,
    $content as xs:string,
    $contentType as xs:string
) as empty-sequence()
{
    let $existing := doc($uri)
    let $test :=
        if(empty($existing))
        then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document to update at '", $uri, "'"))
        else ()
    let $body :=
        if($contentType = "json")
        then json:parse($content)
        else if($contentType = "xml")
        then xdmp:unquote($content, (), ("repair-none", "format-xml"))[1]
        else if($contentType = "text")
        then text { $content }
        else error(xs:QName("corona:INVALID-PARAMETER"), "Invalid content type, must be one of xml or json")
    return
        if($contentType = "text")
        then xdmp:node-replace($existing, $body)
        else xdmp:node-replace($existing/*, $body)
};

declare function store:updateBinaryDocumentContent(
    $uri as xs:string,
    $content as binary(),
    $suppliedContent as xs:string?
) as empty-sequence()
{
    let $suppliedContent :=
        if(exists($suppliedContent))
        then
            if(common:xmlOrJSON($suppliedContent) = "json")
            then json:parse($suppliedContent)
            else xdmp:unquote($suppliedContent, (), ("repair-none", "format-xml"))[1]
        else ()
    let $existing := doc($uri)
    let $test :=
        if(empty($existing))
        then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document to update at '", $uri, "'"))
        else ()

    let $sidecarURI := store:getSidecarURI($uri)
    let $existingSidecar := doc($uri)
    let $sidecar := <corona:sidecar type="binary">{ $suppliedContent }</corona:sidecar>
    let $updateSidecar :=
        if(exists($existingSidecar))
        then xdmp:node-replace($existingSidecar/*, $sidecar)
        else xdmp:document-insert($sidecarURI, $sidecar, (xdmp:default-permissions())) (: XXX - Should grab permissions, collections and quality from binary :)
    return xdmp:node-replace($existing/node(), $content)
};

declare function store:createProperty(
    $name as xs:string,
    $value as xs:string
) as element()
{
    let $test :=
        if(not(matches($name, "[A-Za-z0-9][A-Za-z0-9_\-]*")))
        then error(xs:QName("corona:INVALID-PROPERTY"), concat("The property name '", $name, "' is not valid"))
        else ()
    let $date := dateparser:parse($value)
    let $dateAttribute := if(exists($date)) then attribute normalized-date { $date } else ()
    return element { QName("http://marklogic.com/corona", $name) } { ($dateAttribute, $value) }
};


(:
    Functions to manage document metadata
:)

declare function store:setProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    if(exists($properties))
    then
        if(store:getDocumentType($uri) = "binary")
        then xdmp:document-set-properties(store:getSidecarURI($uri), $properties)
        else xdmp:document-set-properties($uri, $properties)
    else ()
};

declare function store:addProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-add-properties(store:getSidecarURI($uri), $properties)
    else xdmp:document-add-properties($uri, $properties)
};

declare function store:removeProperties(
    $uri as xs:string,
    $properties as xs:string*
) as empty-sequence()
{
    let $properties :=
        for $prop in $properties
        return QName("http://marklogic.com/corona", $prop)
    return
        if(store:getDocumentType($uri) = "binary")
        then xdmp:document-remove-properties(store:getSidecarURI($uri), $properties)
        else xdmp:document-remove-properties($uri, $properties)
};

declare function store:setPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    if(exists($permissions))
    then
        if(store:getDocumentType($uri) = "binary")
        then xdmp:document-set-permissions(store:getSidecarURI($uri), (xdmp:default-permissions(), $permissions))
        else xdmp:document-set-permissions($uri, (xdmp:default-permissions(), $permissions))
    else ()
};

declare function store:addPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-add-permissions(store:getSidecarURI($uri), $permissions)
    else xdmp:document-add-permissions($uri, $permissions)
};

declare function store:removePermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-remove-permissions(store:getSidecarURI($uri), $permissions)
    else xdmp:document-remove-permissions($uri, $permissions)
};

declare function store:setCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    if(empty($collections))
    then ()
    else if(empty(doc($uri)))
    then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document at '", $uri, "'"))
    else if(store:getDocumentType($uri) = "binary")
    then xdmp:document-set-collections(store:getSidecarURI($uri), $collections)
    else xdmp:document-set-collections($uri, $collections)
};

declare function store:addCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-add-collections(store:getSidecarURI($uri), $collections)
    else xdmp:document-add-collections($uri, $collections)
};

declare function store:removeCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-remove-collections(store:getSidecarURI($uri), $collections)
    else xdmp:document-remove-collections($uri, $collections)
};

declare function store:setQuality(
    $uri as xs:string,
    $quality as xs:integer?
) as empty-sequence()
{
    if(exists($quality))
    then
        if(store:getDocumentType($uri) = "binary")
        then xdmp:document-set-quality(store:getSidecarURI($uri), $quality)
        else xdmp:document-set-quality($uri, $quality)
    else ()
};




declare private function store:getDocumentCollections(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    let $uri :=
        if(store:getDocumentType($uri) = "binary")
        then store:getSidecarURI($uri)
        else $uri
    return
        if($outputFormat = "json")
        then json:array(xdmp:document-get-collections($uri))
        else
            for $collection in xdmp:document-get-collections($uri)
            return <corona:collection>{ $collection }</corona:collection>
};

declare private function store:getDocumentProperties(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    let $uri :=
        if(store:getDocumentType($uri) = "binary")
        then store:getSidecarURI($uri)
        else $uri
    return
        if($outputFormat = "json")
        then
            json:object(
                for $property in xdmp:document-properties($uri)/prop:properties/*
                where namespace-uri($property) = "http://marklogic.com/corona"
                return (local-name($property), string($property))
            )
        else
            for $property in xdmp:document-properties($uri)/prop:properties/*
            where namespace-uri($property) = "http://marklogic.com/corona"
            return element { xs:QName(concat("corona:", local-name($property))) } { string($property) }
};

declare private function store:getDocumentPermissions(
    $uri as xs:string,
    $outputFormat as xs:string
) as element()*
{
    if($outputFormat = "json")
    then
        json:object(
            let $uri :=
                if(store:getDocumentType($uri) = "binary")
                then store:getSidecarURI($uri)
                else $uri
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
        let $uri :=
            if(store:getDocumentType($uri) = "binary")
            then store:getSidecarURI($uri)
            else $uri
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
        return element { xs:QName(concat("corona:", $role)) } { for $perm in map:get($permMap, $key) return <corona:permission>{ $perm }</corona:permission> }
};

declare private function store:getDocumentQuality(
    $uri as xs:string
) as xs:decimal
{
    if(store:getDocumentType($uri) = "binary")
    then xdmp:document-get-quality(store:getSidecarURI($uri))
    else xdmp:document-get-quality($uri)
};

declare private function store:highlightContent(
    $content as node(),
    $query as cts:query,
    $outputFormat as xs:string
) as node()?
{
    if($outputFormat = "json")
    then cts:highlight($content, $query, concat('<span class="hit">', $cts:text, '</span>'))
    else if($outputFormat = "xml")
    then cts:highlight($content, $query, <span class="hit">{ $cts:text }</span>)
    else ()
};

declare private function store:wrapContentNodes(
    $nodes as node()*,
    $contentType as xs:string
) as node()
{
    (: If there is more than one node, wrap it :)
    if(count($nodes, 2) = 1)
    then $nodes
    else
        if($contentType = "json")
        then
            if(empty($nodes))
            then json:null()
            else json:array($nodes)
        else if($contentType = "xml")
        then <store:content>{ $nodes }</store:content>
        else $nodes
};

declare private function store:outputDocument(
    $uri as xs:string,
    $content as node()*,
    $include as xs:string*,
    $contentType as xs:string,
    $outputFormat as xs:string
)
{
    if($outputFormat = "json")
    then
        let $content :=
            if($contentType = "json")
            then store:wrapContentNodes($content, $contentType)
            else $content
        return (
            if($include = ("content", "all"))
            then ("content", $content)
            else (),
            if($include = ("collections", "all"))
            then ("collections", store:getDocumentCollections($uri, "json"))
            else (),
            if($include = ("properties", "all"))
            then ("properties", store:getDocumentProperties($uri, "json"))
            else (),
            if($include = ("permissions", "all"))
            then ("permissions", store:getDocumentPermissions($uri, "json"))
            else (),
            if($include = ("quality", "all"))
            then ("quality", store:getDocumentQuality($uri))
            else ()
        )
    else if($outputFormat = "xml")
    then (
        if($include = ("content", "all"))
        then <corona:content>{
            if($contentType = "json")
            then json:serialize(store:wrapContentNodes($content, $contentType))
            else $content
        }</corona:content>
        else (),
        if($include = ("collections", "all"))
        then <corona:collections>{ store:getDocumentCollections($uri, "xml") }</corona:collections>
        else (),
        if($include = ("properties", "all"))
        then <corona:properties>{ store:getDocumentProperties($uri, "xml") }</corona:properties>
        else (),
        if($include = ("permissions", "all"))
        then <corona:permissions>{ store:getDocumentPermissions($uri, "xml") }</corona:permissions>
        else (),
        if($include = ("quality", "all"))
        then <corona:quality>{ store:getDocumentQuality($uri) }</corona:quality>
        else ()
    )
    else ()
};

declare private function store:applyTransformer(
    $name as xs:string,
    $content as node()
) as item()*
{
    let $transformer := manage:getTransformer($name)
    return
        if(exists($transformer/*) and $xsltIsSupported)
        then xdmp:apply($xsltEval, $transformer/*, $content)
        else if(exists($transformer/text()))
        then xdmp:eval(string($transformer), (xs:QName("content"), $content), <options xmlns="xdmp:eval"><isolation>same-statement</isolation></options>)
        else error(xs:QName("corona:INVALID-TRANSFORMER"), "XSLT transformations are not supported in this version of MarkLogic, upgrade to 5.0 or later")
};

declare private function store:getSidecarURI(
    $uri as xs:string
) as xs:string
{
    concat($uri, "-sidecar")
};
