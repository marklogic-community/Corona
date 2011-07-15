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

module namespace common="http://marklogic.com/mljson/common";
import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "path-parser.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "reststore.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace prop="http://xqdev.com/prop" at "properties.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function common:error(
    $statusCode as xs:integer,
    $message as xs:string
) as xs:string
{
    let $set := xdmp:set-response-code($statusCode, $message)
    let $add := xdmp:add-response-header("Date", string(current-dateTime()))
    let $response :=
        json:document(
            json:object((
                "error", json:object((
                    "code", $statusCode,
                    "message", $message
                ))
            ))
        )
    return json:xmlToJSON($response)
};

declare function common:valuesForFacet(
    $query as cts:query,
    $facetName as xs:string
) as xs:string*
{
    let $query := <foo>{ $query }</foo>/*
    let $definition := prop:get(concat("index-", $facetName))
    (: bits -> range, name, key, type, operator :)
    let $bits := tokenize($definition, "/")
    let $operator := if($bits[5]) then common:humanOperatorToMathmatical($bits[5]) else "="
    where $bits[1] = "range"
    return
        if($bits[4] = "date")
        then string($query/descendant-or-self::cts:element-attribute-range-query[cts:element = xs:QName(concat("json:", $bits[3]))][cts:attribute = "normalized-date"][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:dateTime")]/cts:value)
        else if($bits[4] = "string")
        then string($query/descendant-or-self::cts:element-range-query[cts:element = xs:QName(concat("json:", $bits[3]))][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:string")]/cts:value)
        else if($bits[4] = "number")
        then string($query/descendant-or-self::cts:element-range-query[cts:element = xs:QName(concat("json:", $bits[3]))][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:decimal")]/cts:value)
        else ()
};

declare function common:castFromJSONType(
    $value as xs:anySimpleType,
    $type as xs:string
)
{
    common:castFromJSONType(
        if($type = "boolean")
        then <item boolean="{ $value }"/>
        else <item type="{ $type }">{ $value }</item>
    )
};

declare function common:castFromJSONType(
    $value as element()
)
{
    if($value/@type = "number" and $value castable as xs:double)
    then xs:double($value)

    else if(exists($value/@boolean))
    then $value/@boolean = "true"

    else if($value/@type = "date" and exists($value/@normalized-date))
    then xs:dateTime($value/@normalized-date)
    else if($value/@type = "date")
    then dateparser:parse(string($value))

    else if($value/@type = "xml")
    then $value/*

    else xs:string($value)
};

declare function common:humanOperatorToMathmatical(
    $operator as xs:string
) as xs:string
{
    if($operator = "eq")
    then "="
    else if($operator = "ne")
    then "!="
    else if($operator = "lt")
    then "<"
    else if($operator = "le")
    then "<="
    else if($operator = "gt")
    then ">"
    else if($operator = "ge")
    then ">="
    else "="
};

declare function common:indexNameToRangeQuery(
    $name as xs:string,
    $values as element()*,
    $operatorOverride as xs:string?,
    $options as xs:string*,
    $weight as xs:double?
) as cts:element-range-query?
{
    let $prop := prop:get(concat("index-", $name))
    let $bits := tokenize($prop, "/")
    let $key := $bits[3]
    let $type := $bits[4]
    let $operator := common:humanOperatorToMathmatical(($operatorOverride, $bits[5])[1])
    let $values := 
        for $value in $values
        return common:castFromJSONType($value)
    let $QName := xs:QName(concat("json:", $key))
    where exists($prop) and starts-with($prop, "range/")
    return 
        if($values/@type = "boolean" or ($values/@type = "array" and count($values/json:item/@boolean) = count($values/json:item)))
        then cts:element-attribute-range-query($QName, xs:QName("boolean"), "=", $values, $options, $weight)

        else if($values/@type = "date" or ($values/@type = "array" and count($values/json:item/@normalized-date) = count($values/json:item)))
        then cts:element-attribute-range-query($QName, xs:QName("normalized-date"), $operator, $values, $options, $weight)

        else cts:element-range-query($QName, $operator, $values, $options, $weight)
};

declare function common:outputMultipleDocs(
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
                let $doc :=
                    if(exists($returnPath))
                    then path:select($doc, $returnPath)
                    else $doc
                return json:object((
                    "uri", $uri,
                    if($include = ("content", "all"))
                    then ("content", $doc)
                    else (),
                    if($include = ("collections", "all"))
                    then ("collections", reststore:getDocumentCollections($uri))
                    else (),
                    if($include = ("properties", "all"))
                    then ("properties", reststore:getDocumentProperties($uri))
                    else (),
                    if($include = ("permissions", "all"))
                    then ("permissions", reststore:getDocumentPermissions($uri))
                    else (),
                    if($include = ("quality", "all"))
                    then ("quality", reststore:getDocumentQuality($uri))
                    else (),
                    if($include = ("snippet", "all"))
                    then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*)))
                    else ()
                ))
            )
        ))
    )
};

declare private function common:translateSnippet(
    $snippet as element(search:snippet)
) as element(json:item)
{
    json:array(
        for $match in $snippet/search:match
        return string-join(
            for $node in $match/node()
            return
                if($node instance of element(search:highlight))
                then concat("<span class='hit'>", string($node), "</span>")
                else string($node)
        , "")
    )
};
