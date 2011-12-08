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

(:
    Can take in a JSON document, XML document, text document, binary node or binary sidecar.
    Will *not* output just the raw document if include equals and only equals "content", use doc() for that instead.
:)
declare function store:outputDocument(
    $doc as document-node(),
    $include as xs:string+,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $highlightQuery as cts:query?,
    $outputFormat as xs:string
) as element()
{
    let $documentType := store:getDocumentTypeFromDoc($doc)
    (:
       contentURI: holds the searchable content
       documentURI: holds the document that the user inserted
    :)
    let $contentURI :=
        if($documentType = "binary")
        then store:getSidecarURI(base-uri($doc))
        else base-uri($doc)
    let $documentURI :=
        if($documentType = "binary-sidecar")
        then store:getDocumentURIFromSidecar($contentURI)
        else $contentURI

    let $contentType :=
        if($documentType = "binary-sidecar")
        then string($doc/corona:sidecar/corona:suppliedContent/@format)
        else if($documentType = "binary")
        then string(doc($contentURI)/corona:sidecar/corona:suppliedContent/@format)
        else $documentType

    let $collections := xdmp:document-get-collections($contentURI)

    let $searchableContent :=
        if($documentType = "text")
        then $doc/text()
        else if($documentType = "binary-sidecar")
        then $doc/corona:sidecar/corona:suppliedContent/*
        else if($documentType = "binary")
        then doc($contentURI)/corona:sidecar/corona:suppliedContent/*
        else if($documentType = "json")
        then $doc/json:json
        else $doc

    (: Perform the path extraction if one was provided :)
    let $content :=
        if(exists($extractPath) and $contentType = "xml")
        then store:wrapContentNodes(path:select($searchableContent, $extractPath, "xpath"), $contentType)
        else if(exists($extractPath) and $contentType = "json")
        then store:wrapContentNodes(path:select($searchableContent, $extractPath, "json"), $contentType)
        else $searchableContent

    (: Highlight the content body :)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then store:highlightContent($content, $highlightQuery, $outputFormat)
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
        if($include = ("snippet", "all") and exists($highlightQuery))
        then common:translateSnippet(search:snippet($doc, <cast>{ $highlightQuery }</cast>/*), $outputFormat)
        else ()

    return
        if($outputFormat = "json")
        then json:object((
            "uri", $documentURI,
            if($include = ("content", "all"))
            then ("content", store:wrapContentNodes($content, $contentType))
            else (),
            if($include = ("collections", "all"))
            then ("collections", store:getDocumentCollections($contentURI, "json"))
            else (),
            if($include = ("properties", "all"))
            then ("properties", store:getDocumentProperties($contentURI, "json"))
            else (),
            if($include = ("permissions", "all"))
            then ("permissions", store:getDocumentPermissions($contentURI, "json"))
            else (),
            if($include = ("quality", "all"))
            then ("quality", store:getDocumentQuality($contentURI))
            else (),
            if($include = ("snippet", "all") and exists($highlightQuery))
            then ("snippet", $snippet)
            else (),
            if($include = ("confidence", "all") and exists($highlightQuery))
            then ("confidence", cts:confidence($doc))
            else (),
            if($documentType = ("binary", "binary-sidecar") and $include = ("binaryMetadata", "all"))
            then ("binaryMetadata", json:object((
                for $meta in doc($contentURI)/corona:sidecar/corona:meta/*
                return (local-name($meta), string($meta))
            )))
            else ()
        ))
        else if($outputFormat = "xml")
        then <corona:result>{(
            <corona:uri>{ $documentURI }</corona:uri>,
            if($include = ("content", "all"))
            then <corona:content>{
                if($contentType = "json")
                then json:serialize(store:wrapContentNodes($content, $contentType))
                else $content
            }</corona:content>
            else (),
            if($include = ("collections", "all"))
            then <corona:collections>{ store:getDocumentCollections($contentURI, "xml") }</corona:collections>
            else (),
            if($include = ("properties", "all"))
            then <corona:properties>{ store:getDocumentProperties($contentURI, "xml") }</corona:properties>
            else (),
            if($include = ("permissions", "all"))
            then <corona:permissions>{ store:getDocumentPermissions($contentURI, "xml") }</corona:permissions>
            else (),
            if($include = ("quality", "all"))
            then <corona:quality>{ store:getDocumentQuality($contentURI) }</corona:quality>
            else (),
            if($include = ("snippet", "all") and exists($highlightQuery))
            then <corona:snippet>{ $snippet }</corona:snippet>
            else (),
            if($include = ("confidence", "all") and exists($highlightQuery))
            then <corona:confidence>{ cts:confidence($doc) }</corona:confidence>
            else (),
            if($documentType = ("binary", "binary-sidecar") and $include = ("binaryMetadata", "all"))
            then <corona:binaryMetadata>{ doc($contentURI)/corona:sidecar/corona:meta/* }</corona:binaryMetadata>
            else ()
        )}</corona:result>
        else ()
};

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
) as element()
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
        return store:outputDocument($doc, $include, $extractPath, $applyTransform, $query, $outputFormat)
    let $executionTime := substring(string(xdmp:query-meters()/*:elapsed-time), 3, 4)
    return
        if($outputFormat = "json")
        then json:object((
            "meta", json:object((
                "start", $start,
                "end", $end,
                "total", $total,
                "executionTime", $executionTime
            )),
            if($include = "none") then () else ("results", json:array($results))
        ))
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
    let $test := store:validateURI($newURI)
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
    store:getDocumentTypeFromDoc(doc($uri))
};

declare function store:getDocumentTypeFromDoc(
    $doc as item()
) as xs:string?
{
    if(exists($doc/json:json))
    then "json"
    else if(exists($doc/corona:sidecar))
    then "binary-sidecar"
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
) as element()
{
    if(store:documentExists($uri))
    then (
        if(store:getDocumentType($uri) = "binary" and exists(doc(store:getSidecarURI($uri))))
        then xdmp:document-delete(store:getSidecarURI($uri))
        else (),
        xdmp:document-delete($uri),
        if($outputFormat = "json")
        then json:object((
            "meta", json:object((
                "deleted", 1,
                "numRemaining", 0
            )),
            if($includeURIs)
            then ("uris", json:array($uri))
            else ()
        ))
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
) as element()
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
            then json:object((
                "meta", json:object((
                    "deleted", $numDeleted,
                    "numRemaining", $count - $numDeleted
                )),
                if($includeURIs)
                then ("uris", json:array($deletedURIs))
                else ()
            ))
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
    let $test := store:validateURI($uri)
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
    $quality as xs:integer?,
    $extractMetadata as xs:boolean,
    $extractContent as xs:boolean
) as empty-sequence()
{
    let $test := store:validateURI($uri)
    let $sidecarURI := store:getSidecarURI($uri)
    let $sidecar := store:createSidecarDocument($uri, $content, $suppliedContent, $extractMetadata, $extractContent)
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
    $suppliedContent as xs:string?,
    $extractMetadata as xs:boolean,
    $extractContent as xs:boolean
) as empty-sequence()
{
    let $test := store:validateURI($uri)
    let $existing := doc($uri)
    let $test :=
        if(empty($existing))
        then error(xs:QName("corona:DOCUMENT-NOT-FOUND"), concat("There is no document to update at '", $uri, "'"))
        else ()

    let $sidecarURI := store:getSidecarURI($uri)
    let $existingSidecar := doc($sidecarURI)
    let $sidecar := store:createSidecarDocument($uri, $content, $suppliedContent, $extractMetadata, $extractContent)
    let $updateSidecar :=
        if(exists($existingSidecar))
        then xdmp:node-replace($existingSidecar/*, $sidecar)
        else xdmp:document-insert($sidecarURI, $sidecar, (xdmp:default-permissions(), xdmp:document-get-permissions($uri)), xdmp:document-get-collections($uri), xdmp:document-get-quality($uri))
    return xdmp:node-replace($existing/node(), $content)
};

declare function store:getBinaryContentType(
    $doc as binary()
) as xs:string
{
    (doc(store:getSidecarURI(base-uri($doc)))/corona:sidecar/corona:meta/corona:contentType, "application/octet-stream")[1]
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
        return element { xs:QName(concat("corona:", $role)) } { for $perm in map:get($permMap, $key) return <corona:permission>{ $perm }</corona:permission> }
};

declare private function store:getDocumentQuality(
    $uri as xs:string
) as xs:decimal
{
    xdmp:document-get-quality($uri)
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

declare private function store:getDocumentURIFromSidecar(
    $sidecarURI as xs:string
) as xs:string
{
    replace($sidecarURI, "-sidecar$", "")
};

declare private function store:createSidecarDocument(
    $documentURI as xs:string,
    $content as binary(),
    $suppliedContent as xs:string?,
    $extractMetadata as xs:boolean,
    $extractContent as xs:boolean
) as element(corona:sidecar)
{
    let $suppliedContentFormat := common:xmlOrJSON($suppliedContent)
    let $suppliedContent :=
        if(exists($suppliedContent))
        then
            if($suppliedContentFormat = "json")
            then json:parse($suppliedContent)
            else xdmp:unquote($suppliedContent, (), ("repair-none", "format-xml"))[1]
        else ()
    return <corona:sidecar type="binary" original="{ $documentURI }">
        <corona:suppliedContent format="{ $suppliedContentFormat }">{ $suppliedContent }</corona:suppliedContent>
        {
            if($extractMetadata = false() and $extractContent = false())
            then ()
            else

            let $extratedInfo := try {
                xdmp:apply(xdmp:function(xs:QName("xdmp:document-filter")), $content)
            }
            catch ($e) {
                ()
            }
            where exists($extratedInfo)
            return (
                if($extractMetadata)
                then
                <corona:meta>{(
                    if(exists($extratedInfo/*:html/*:head/*:title))
                    then <corona:title>{ string($extratedInfo/*:html/*:head/*:title) }</corona:title>
                    else (),

                    for $item in $extratedInfo/*:html/*:head/*:meta
                    let $name := string-join(
                        for $bit at $pos in tokenize($item/@name, "\-| |_")
                        return 
                            if($pos > 1)
                            then concat(upper-case(substring($bit, 1, 1)), substring($bit, 2))
                            else
                                if(lower-case(substring($bit, 2, 1)) = substring($bit, 2, 1))
                                then concat(lower-case(substring($bit, 1, 1)), substring($bit, 2))
                                else $bit
                    , "")
                    let $element := element { xs:QName(concat("corona:", json:escapeNCName(string($name)))) } { string($item/@content) }
                    where $name != "filterCapabilities"
                    return
                        if($name = "dimensions" and count(tokenize($item/@content, " x ")) = 2)
                        then ($element, <corona:width>{ substring-before($item/@content, " x ") }</corona:width>, <corona:height>{ substring-after($item/@content, " x ") }</corona:height>)
                        else $element
                )}</corona:meta>
                else (),

                if(exists($extratedInfo/*:html/*:body) and $extractContent)
                then
                <corona:extractedContent>{
                    for $para in $extratedInfo/*:html/*:body/*:p
                    let $string := normalize-space($para)
                    where string-length($string)
                    return <corona:extractedPara>{ $string }</corona:extractedPara>
                }</corona:extractedContent>
                else ()
            )
        }
    </corona:sidecar>
};

declare private function store:validateURI(
    $uri as xs:string
) as empty-sequence()
{
    if(starts-with($uri, "_/") or ends-with($uri, "-sidecar"))
    then error(xs:QName("INVALID-URI"), "Document URI's starting with '_/' or ending with '-sidecar' are reserved")
    else ()
};
