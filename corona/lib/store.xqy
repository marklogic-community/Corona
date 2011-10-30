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

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "path-parser.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "manage.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";

declare namespace corona="http://marklogic.com/corona";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function store:outputMultipleDocuments(
    $docs as element()*,
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
        let $documentType :=
            if($collections = $const:JSONCollection)
            then "json"
            else if($collections = $const:XMLCollection)
            then "xml"
            else ()

        (: Perform the path extraction if one was provided :)
        let $content :=
            if(exists($extractPath))
            then store:wrapContentNodes(path:select($doc, $extractPath, $documentType), $documentType)
            else $doc

        (: Highlight the content body :)
        let $content :=
            if($include = ("highlighting") and exists($query))
            then store:highlightContent($content, $query, $outputFormat)
            else $content

        (: Apply the transformation :)
        let $content :=
            if(exists($applyTransform))
            then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
            else $content

        (: If the wrapper element from wrapContentNodes is still sticking around, remove it :)
        let $content :=
            if($documentType = "xml" and namespace-uri($content) = "http://marklogic.com/corona/store")
            then $content/*
            else $content

        let $snippet :=
            if($include = ("snippet", "all"))
            then common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*), $outputFormat)
            else ()

        where exists($documentType)
        return
            if($outputFormat = "json")
            then json:object((
                "uri", $uri,
                store:outputDocument($uri, $content, $include, $documentType, $outputFormat),
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
                store:outputDocument($uri, $content, $include, $documentType, $outputFormat),
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

declare function store:deleteDocument(
    $uri as xs:string,
    $includeURIs as xs:boolean,
    $outputFormat as xs:string
) as xs:string
{
    if(xdmp:document-get-collections($uri) = ($const:JSONCollection, $const:XMLCollection))
    then (
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
        else common:error(400, "corona:INVALID-OUTPUT-FORMAT", concat("The output format '", $outputFormat, "' isn't valid"), "json")
    )
    else common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no document to delete at '", $uri, "'"), $outputFormat)
};

declare function store:deleteDocumentsWithQuery(
    $query as cts:query,
    $bulkDelete as xs:boolean,
    $includeURIs as xs:boolean,
    $limit as xs:integer?,
    $outputFormat as xs:string
) as xs:string
{
    let $docs :=
        if(exists($limit))
        then cts:search(collection(($const:JSONCollection, $const:XMLCollection)), $query)[1 to $limit]
        else cts:search(collection(($const:JSONCollection, $const:XMLCollection)), $query)
    let $count := if(exists($docs)) then cts:remainder($docs[1]) else 0
    let $numDeleted :=
        if(exists($limit))
        then $limit
        else $count
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
            else if($outputFormat = "xml")
            then <corona:results>
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
            else common:error(400, "corona:INVALID-OUTPUT-FORMAT", concat("The output format '", $outputFormat, "' isn't valid"), "json")
        else if($count = 0)
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", "DELETE query doesn't match any documents", $outputFormat)
        else common:error(400, "corona:BULK-DELETE", "DELETE query matches more than one document without enabling bulk deletes", $outputFormat)
};

declare function store:getDocument(
    $uri as xs:string,
    $include as xs:string*,
    $extractPath as xs:string?,
    $applyTransform as xs:string?,
    $highlightQuery as cts:query?,
    $outputFormat as xs:string
) as xs:string
{
    if(not(xdmp:document-get-collections($uri) = ($const:JSONCollection, $const:XMLCollection)))
    then common:error(404, "corona:DOCUMENT-NOT-FOUND", "Document not found", $outputFormat)
    else

    let $includeContent := $include = ("content", "all")
    let $includeCollections := $include = ("collections", "all")
    let $includeProperties := $include = ("properties", "all")
    let $includePermissions := $include = ("permissions", "all")
    let $includeQuality := $include = ("quality", "all")

    let $collections := xdmp:document-get-collections($uri)
    let $documentType :=
        if($collections = $const:JSONCollection)
        then "json"
        else if($collections = $const:XMLCollection)
        then "xml"
        else ()

    let $content :=
        if(exists($extractPath))
        then store:wrapContentNodes(path:select(doc($uri)/*, $extractPath, $documentType), $documentType)
        else doc($uri)
    let $content :=
        if($include = ("highlighting") and exists($highlightQuery))
        then store:highlightContent($content, $highlightQuery, $documentType)
        else $content
    let $content :=
        if(exists($applyTransform))
        then xdmp:xslt-eval(manage:getTransformer($applyTransform), $content)
        else $content
    let $content :=
        if(namespace-uri($content) = "http://marklogic.com/corona/store")
        then $content/*
        else $content
    return
        if($includeContent and not($includeCollections) and not($includeProperties) and not($includePermissions) and not($includeQuality))
        then
            if($outputFormat = "xml")
            then $content
            else json:serialize($content)
        else
            if($outputFormat = "xml")
            then <corona:response>{ store:outputDocument($uri, $content, $include, "xml", "xml") }</corona:response>
            else json:serialize(json:document(
                json:object(store:outputDocument($uri, $content, $include, "json", "json"))
            ))
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
    JSON Document management
:)

declare function store:insertJSONDocument(
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

declare function store:updateJSONDocumentContent(
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


(:
    XML Document management
:)

declare function store:insertXMLDocument(
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

declare function store:updateXMLDocumentContent(
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
    let $existing := store:getRawXMLDoc($uri)
    let $test :=
        if(empty($existing))
        then common:error(404, "corona:DOCUMENT-NOT-FOUND", concat("There is no XML document to update at '", $uri, "'"), "xml")
        else ()
    where exists($existing)
    return xdmp:node-replace($existing, $body)
};

declare private function store:getRawXMLDoc(
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

declare function store:setProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    if(exists($properties))
    then xdmp:document-set-properties($uri, $properties)
    else ()
};

declare function store:addProperties(
    $uri as xs:string,
    $properties as element()*
) as empty-sequence()
{
    xdmp:document-add-properties($uri, $properties)
};

declare function store:removeProperties(
    $uri as xs:string,
    $properties as xs:string*
) as empty-sequence()
{
    let $properties :=
        for $prop in $properties
        return QName("http://marklogic.com/corona", $prop)
    return xdmp:document-remove-properties($uri, $properties)
};

declare function store:setPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    if(exists($permissions))
    then xdmp:document-set-permissions($uri, $permissions)
    else ()
};

declare function store:addPermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    xdmp:document-add-permissions($uri, $permissions)
};

declare function store:removePermissions(
    $uri as xs:string,
    $permissions as element()*
) as empty-sequence()
{
    xdmp:document-remove-permissions($uri, $permissions)
};

declare function store:setCollections(
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

declare function store:addCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    xdmp:document-add-collections($uri, $collections)
};

declare function store:removeCollections(
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    xdmp:document-remove-collections($uri, $collections)
};

declare function store:setQuality(
    $uri as xs:string,
    $quality as xs:integer?
) as empty-sequence()
{
    if(exists($quality))
    then xdmp:document-set-quality($uri, $quality)
    else ()
};




declare private function store:getDocumentCollections(
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
    $documentType as xs:string
) as node()
{
    (: If there is more than one node, wrap it :)
    if(count($nodes, 2) = 1)
    then $nodes
    else
        if($documentType = "json")
        then
            if(empty($nodes))
            then json:null()
            else json:array($nodes)
        else if($documentType = "xml")
        then <store:content>{ $nodes }</store:content>
        else $nodes
};

declare private function store:outputDocument(
    $uri as xs:string,
    $content as node()*,
    $include as xs:string*,
    $documentType as xs:string,
    $outputFormat as xs:string
)
{
    if($outputFormat = "json")
    then
        let $content :=
            if($documentType = "json")
            then store:wrapContentNodes($content, $documentType)
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
            if($documentType = "json")
            then json:serialize(store:wrapContentNodes($content, $documentType))
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
