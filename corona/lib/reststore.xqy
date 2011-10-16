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

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "path-parser.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "manage.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace corona="http://marklogic.com/corona";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

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
    then common:error(404, "corona:DOCUMENT-NOT-FOUND", "Document not found", "json")
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")
    let $content :=
        if(exists($extractPath))
        then path:select(doc($uri)/json:json, $extractPath, "json")
        else root(doc($uri)/json:json)
    let $content :=
        if(empty($content))
        then json:null()
        else if(count($content, 1) = 1)
        then $content
        else json:array($content)
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
        then json:serialize($content)
        else json:serialize(json:document(
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
    let $start :=
        if($total = 0)
        then 0
        else $start
    let $end :=
        if(empty($end))
        then $start
        else $end

    return json:serialize(
        json:object((
            "meta", json:object((
                "start", $start,
                "end", $end,
                "total", $total,
                "executionTime", substring(string(xdmp:query-meters()/*:elapsed-time), 3, 4)
            )),
            if($include = "none")
            then ()
            else (
                "results", json:array(
                    for $doc in $docs
                    let $uri := base-uri($doc)
                    let $content :=
                        if(exists($extractPath))
                        then path:select($doc, $extractPath, "json")
                        else $doc
                    let $content :=
                        if(empty($content))
                        then json:null()
                        else if(count($content, 1) = 1)
                        then $content
                        else json:array($content)
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
                        then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*), "json"))
                        else (),
                        if($include = ("confidence", "all"))
                        then ("confidence", cts:confidence($doc))
                        else ()
                    ))
                )
            )
        ))
    )
};

declare private function reststore:outputJSONDocument(
    $uri as xs:string,
    $content as node()*,
    $include as xs:string*
)
{
    let $content :=
        if(empty($content))
        then json:null()
        else if(count($content, 1) = 1)
        then $content
        else json:array($content)
    return
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
            json:parse($content)
        }
        catch ($e) {
            common:error(400, "corona:INVALID-PARAMETER", "Invalid JSON", "json"),
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
            json:parse($content)
        }
        catch ($e) {
            common:error(400, "corona:INVALID-PAPARAMETER", "Invalid JSON", "json"),
            xdmp:log($e)
        }
    let $existing := doc($uri)/json:json
    let $test :=
        if(empty($existing))
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no JSON document to update at '", $uri, "'"), "json")
        else ()
    where exists($existing)
    return xdmp:node-replace($existing, $body)
};

declare function reststore:deleteJSONDocument(
    $uri as xs:string,
    $includeURIs as xs:boolean
) as xs:string
{
    if(exists(doc($uri)/json:json))
    then (
        xdmp:document-delete($uri),
        json:serialize(json:object((
            "meta", json:object((
                "deleted", 1,
                "numRemaining", 0
            )),
            if($includeURIs)
            then ("uris", json:array($uri))
            else ()
        )))
    )
    else common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no JSON document to delete at '", $uri, "'"), "json")
};

declare function reststore:deleteJSONDocumentsWithQuery(
    $query as cts:query,
    $bulkDelete as xs:boolean,
    $includeURIs as xs:boolean,
    $limit as xs:integer?
) as xs:string
{
    let $docs :=
        if(exists($limit))
        then cts:search(collection($const:JSONCollection), $query)[1 to $limit]
        else cts:search(collection($const:JSONCollection), $query)
    let $count := if(exists($docs)) then cts:remainder($docs[1]) else 0
    let $numDeleted :=
        if(exists($limit))
        then $limit
        else $count
    return
        if($bulkDelete or $count = 1)
        then
            json:serialize(json:object((
                "meta", json:object((
                    "deleted", $numDeleted,
                    "numRemaining", $count - $numDeleted
                )),
                if($includeURIs)
                then (
                    "uris",
                    json:array(
                        for $doc in $docs
                        let $delete := xdmp:document-delete(base-uri($doc))
                        return base-uri($doc)
                    )
                )
                else
                    for $doc in $docs
                    return xdmp:document-delete(base-uri($doc))
            )))
        else if($count = 0)
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", "DELETE query doesn't match any documents", "json")
        else common:error(400, "corona:BULK-DELETE", "DELETE query matches more than one document without enabling bulk deletes", "json")
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
    then common:error(404, "corona:DOCUMENT-NOT-FOUND", "Document not found", "xml")
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")
    let $content :=
        if(exists($extractPath))
        then path:select(reststore:getRawXMLDoc($uri), $extractPath, "xml")
        else reststore:getRawXMLDoc($uri)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then reststore:highlightXMLContent(if(count($content, 2) > 1) then <reststore:content>{ $content }</reststore:content> else $content, $highlightQuery)
        else $content
    let $content :=
        if(exists($applyTransform))
        then xdmp:xslt-eval(manage:getTransformer($applyTransform), if(count($content, 2) > 1) then <reststore:content>{ $content }</reststore:content> else $content)
        else $content
    let $content :=
        if(namespace-uri($content) = "http://marklogic.com/reststore")
        then $content/*
        else $content
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then $content
        else <corona:response>{ reststore:outputXMLDocument($uri, $content, $include) }</corona:response>
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
    let $start :=
        if($total = 0)
        then 0
        else $start
    let $end :=
        if(empty($end))
        then $start
        else $end
    return 
        <corona:response>
            <corona:meta>
                <corona:start>{ $start }</corona:start>
                <corona:end>{ $end }</corona:end>
                <corona:total>{ $total }</corona:total>
                <corona:executionTime>{ substring(string(xdmp:query-meters()/*:elapsed-time), 3, 4) }</corona:executionTime>
            </corona:meta>
            {
            if($include = "none")
            then ()
            else <corona:results>{
                    for $doc in $docs
                    let $uri := base-uri($doc)
                    let $content :=
                        if(exists($extractPath))
                        then path:select(root($doc), $extractPath, "xml")
                        else $doc
                    let $content :=
                        if($include = ("highlighting") and exists($query))
                        then reststore:highlightXMLContent(if(count($content, 2) > 1) then <reststore:content>{ $content }</reststore:content> else $content, $query)
                        else $content
                    let $content :=
                        if(exists($applyTransform))
                        then xdmp:xslt-eval(manage:getTransformer($applyTransform), if(count($content, 2) > 1) then <reststore:content>{ $content }</reststore:content> else $content)
                        else $content
                    let $content :=
                        if(namespace-uri($content) = "http://marklogic.com/reststore")
                        then $content/*
                        else $content
                    return <corona:result>{(
                        <corona:uri>{ $uri }</corona:uri>,
                        reststore:outputXMLDocument($uri, $content, $include),
                        if($include = ("snippet", "all"))
                        then <corona:snippet>{ common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*), "xml") }</corona:snippet>
                        else (),
                        if($include = ("confidence", "all"))
                        then <corona:confidence>{ cts:confidence($doc) }</corona:confidence>
                        else ()
                    )}</corona:result>
                }</corona:results>
            }
        </corona:response>
};

declare private function reststore:outputXMLDocument(
    $uri as xs:string,
    $content as node()*,
    $include as xs:string*
) as element()*
{
    if($include = ("content", "all"))
    then <corona:content>{ $content }</corona:content>
    else (),
    if($include = ("collections", "all"))
    then <corona:collections>{ reststore:getDocumentCollections($uri, "xml") }</corona:collections>
    else (),
    if($include = ("properties", "all"))
    then <corona:properties>{ reststore:getDocumentProperties($uri, "xml") }</corona:properties>
    else (),
    if($include = ("permissions", "all"))
    then <corona:permissions>{ reststore:getDocumentPermissions($uri, "xml") }</corona:permissions>
    else (),
    if($include = ("quality", "all"))
    then <corona:quality>{ reststore:getDocumentQuality($uri) }</corona:quality>
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
            common:error(400, "corona:INVALID-PARAMETER", "Invalid XML", "xml"),
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
            common:error(400, "corona:INVALID-PARAMETER", "Invalid XML", "xml"),
            xdmp:log($e)
        }
    let $existing := reststore:getRawXMLDoc($uri)
    let $test :=
        if(empty($existing))
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no XML document to update at '", $uri, "'"), "xml")
        else ()
    where exists($existing)
    return xdmp:node-replace($existing, $body)
};

declare function reststore:deleteXMLDocument(
    $uri as xs:string,
    $includeURIs as xs:boolean
) as element()
{
    if(exists(reststore:getRawXMLDoc($uri)))
    then (
        xdmp:document-delete($uri),
        <corona:results>
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
    )
    else common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no XML document to delete at '", $uri, "'"), "xml")
};

declare function reststore:deleteXMLDocumentsWithQuery(
    $query as cts:query,
    $bulkDelete as xs:boolean,
    $includeURIs as xs:boolean,
    $limit as xs:integer?
) as element()
{
    let $docs :=
        if(exists($limit))
        then cts:search(collection($const:XMLCollection), $query)[1 to $limit]
        else cts:search(collection($const:XMLCollection), $query)
    let $count := if(exists($docs)) then cts:remainder($docs[1]) else 0
    let $numDeleted :=
        if(exists($limit))
        then $limit
        else $count
    return
        if($bulkDelete or $count = 1)
        then
            <corona:results>
                <corona:meta>
                    <corona:deleted>{ $numDeleted }</corona:deleted>
                    <corona:numRemaining>{ $count - $numDeleted }</corona:numRemaining>
                </corona:meta>
                {
                    if($includeURIs)
                    then <corona:uris>{
                        for $doc in $docs
                        let $delete := xdmp:document-delete(base-uri($doc))
                        return <corona:uri>{ base-uri($doc) }</corona:uri>
                    }</corona:uris>
                    else 
                        for $doc in $docs
                        return xdmp:document-delete(base-uri($doc))
                }
            </corona:results>
        else if($count = 0)
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", "DELETE query doesn't match any documents", "xml")
        else common:error(400, "corona:BULK-DELETE", "DELETE query matches more than one document without enabling bulk deletes", "xml")
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
        return <corona:collection>{ $collection }</corona:collection>
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
        return element { xs:QName(concat("corona:", local-name($property))) } { string($property) }
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
        return element { xs:QName(concat("corona:", $role)) } { for $perm in map:get($permMap, $key) return <corona:permission>{ $perm }</corona:permission> }
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
    cts:highlight($content, $query, <span class="hit">{ $cts:text }</span>)
};
