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
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";
import module namespace config="http://marklogic.com/mljson/index-config" at "index-config.xqy";

declare namespace search="http://marklogic.com/appservices/search";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function common:error(
    $statusCode as xs:integer,
    $message as xs:string,
    $outputFormat as xs:string
)
{
    let $set := xdmp:set-response-code($statusCode, $message)
    let $add := xdmp:add-response-header("Date", string(current-dateTime()))
    return
        if($outputFormat = "xml")
        then
            (: XXX - Will need to output in a real XML format :)
            <error>
                <code>{ $statusCode }</code>
                <message>{ $message }</message>
            </error>
        else
            json:xmlToJSON(json:document(
                json:object((
                    "error", json:object((
                        "code", $statusCode,
                        "message", $message
                    ))
                ))
            ))
};

declare function common:valuesForFacet(
    $query as cts:query,
    $facetName as xs:string
) as xs:string*
{
    let $query := <foo>{ $query }</foo>/*
    let $index := config:get($facetName)
    let $operator := if(exists($index/operator)) then common:humanOperatorToMathmatical($index/operator) else "="
    where $index/@type = "range"
    return
        if($index/structure = "json")
        then
            if($index/type = "date")
            then string($query/descendant-or-self::cts:element-attribute-range-query[cts:element = xs:QName(concat("json:", $index/key))][cts:attribute = xs:QName("normalized-date")][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:dateTime")]/cts:value)
            else if($index/type = "string")
            then string($query/descendant-or-self::cts:element-range-query[cts:element = xs:QName(concat("json:", $index/key))][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:string")]/cts:value)
            else if($index/type = "number")
            then string($query/descendant-or-self::cts:element-range-query[cts:element = xs:QName(concat("json:", $index/key))][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:decimal")]/cts:value)
            else ()
        else if($index/structure = "xmlelement")
        then string($query/descendant-or-self::cts:element-range-query[cts:element = xs:QName($index/element)][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:string")]/cts:value)
        else if($index/structure = "xmlattribute")
        then string($query/descendant-or-self::cts:element-attribute-range-query[cts:element = xs:QName($index/element)][cts:attribute = xs:QName($index/attribute)][@operator = $operator][cts:value/@xsi:type = xs:QName("xs:dateTime")]/cts:value)
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

declare function common:castAs(
    $value as xs:anySimpleType,
    $type as xs:string
)
{
    if($type = "string") then xs:string($value)
    else if($type = "boolean") then xs:boolean($value)
    else if($type = "decimal") then xs:decimal($value)
    else if($type = "float") then xs:float($value)
    else if($type = "double") then xs:double($value)
    else if($type = "duration") then xs:duration($value)
    else if($type = "dateTime") then xs:dateTime($value)
    else if($type = "time") then xs:time($value)
    else if($type = "date") then xs:date($value)
    else if($type = "gYearMonth") then xs:gYearMonth($value)
    else if($type = "gYear") then xs:gYear($value)
    else if($type = "gMonthDay") then xs:gMonthDay($value)
    else if($type = "gDay") then xs:gDay($value)
    else if($type = "gMonth") then xs:gMonth($value)
    else if($type = "hexBinary") then xs:hexBinary($value)
    else if($type = "base64Binary") then xs:base64Binary($value)
    else if($type = "QName") then xs:QName($value)
    else if($type = "integer") then xs:integer($value)
    else if($type = "nonPositiveInteger") then xs:nonPositiveInteger($value)
    else if($type = "negativeInteger") then xs:negativeInteger($value)
    else if($type = "long") then xs:long($value)
    else if($type = "int") then xs:int($value)
    else if($type = "short") then xs:short($value)
    else if($type = "byte") then xs:byte($value)
    else if($type = "nonNegativeInteger") then xs:nonNegativeInteger($value)
    else if($type = "unsignedLong") then xs:unsignedLong($value)
    else if($type = "unsignedInt") then xs:unsignedInt($value)
    else if($type = "unsignedShort") then xs:unsignedShort($value)
    else if($type = "unsignedByte") then xs:unsignedByte($value)
    else if($type = "positiveInteger") then xs:positiveInteger($value)
    else xs:string($value)
};

declare function common:humanOperatorToMathmatical(
    $operator as xs:string?
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
    let $index := config:get($name)
    let $operator := common:humanOperatorToMathmatical(($operatorOverride, $index/operator, "eq")[1])
    let $values := 
        if($index/structure = "json")
        then
            for $value in $values
            return common:castFromJSONType($value)
        else
            for $value in $values
            where xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $index/type, $value)
            return common:castAs($value, $index/type)
    where $index/@type = "range"
    return 
        if($index/structure = "json")
        then
            if($index/type = "boolean")
            then cts:element-attribute-range-query(xs:QName(concat("json:", $index/key)), xs:QName("boolean"), "=", $values, $options, $weight)
            else if($index/type = "date")
            then cts:element-attribute-range-query(xs:QName(concat("json:", $index/key)), xs:QName("normalized-date"), $operator, $values, $options, $weight)
            else cts:element-range-query(xs:QName(concat("json:", $index/key)), $operator, $values, $options, $weight)
        else if($index/structure = "xmlelement")
        then cts:element-range-query(xs:QName($index/element), $operator, $values, $options, $weight)
        else if($index/structure = "xmlattribute")
        then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), $operator, $values, $options, $weight)
        else ()
};

declare function common:translateSnippet(
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
