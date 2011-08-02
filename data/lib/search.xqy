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

module namespace search="http://marklogic.com/mljson/search";

import module namespace common="http://marklogic.com/mljson/common" at "common.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function search:bucketLabelToQuery(
    $index as element(index),
    $bucketLabel as xs:string
) as cts:query?
{
    search:bucketLabelToQuery($index, $bucketLabel, (), ())
};

declare function search:bucketLabelToQuery(
    $index as element(index),
    $bucketLabel as xs:string,
    $options as xs:string*,
    $weight as xs:double?
) as cts:query?
{
    let $bucketBits := $index/buckets/*
    let $positionOfBucketLabel :=
        for $bucket at $pos in $bucketBits
        where local-name($bucket) = "label" and string($bucket) = $bucketLabel
        return $pos

    let $lowerBound :=
        if($positionOfBucketLabel > 1)
        then $bucketBits[$positionOfBucketLabel - 1]
        else ()
    let $upperBound :=
        if($positionOfBucketLabel < count($bucketBits))
        then $bucketBits[$positionOfBucketLabel + 1]
        else ()

    let $options :=
        if($index/type = "string")
        then ($options, "collation=http://marklogic.com/collation/")
        else $options

    where exists($positionOfBucketLabel)
    return
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:and-query((
                if(exists($lowerBound))
                then cts:element-attribute-range-query(xs:QName(concat("json:", $index/key)), xs:QName("normalized-date"), ">=", common:castFromJSONType($lowerBound, "date"), $options, $weight)
                else (),
                if(exists($upperBound))
                then cts:element-attribute-range-query(xs:QName(concat("json:", $index/key)), xs:QName("normalized-date"), "<", common:castFromJSONType($upperBound, "date"), $options, $weight)
                else ()
            ))
            else cts:and-query((
                if(exists($lowerBound))
                then cts:element-range-query(xs:QName(concat("json:", $index/key)), ">=", common:castFromJSONType($lowerBound, $index/type), $options, $weight)
                else (),
                if(exists($upperBound))
                then cts:element-range-query(xs:QName(concat("json:", $index/key)), "<", common:castFromJSONType($upperBound, $index/type), $options, $weight)
                else ()
            ))
        else if($index/structure = "xmlelement")
        then cts:and-query((
            if(exists($lowerBound))
            then cts:element-range-query(xs:QName($index/element), ">=", common:castAs($lowerBound, $index/type), $options, $weight)
            else (),
            if(exists($upperBound))
            then cts:element-range-query(xs:QName($index/element), "<", common:castAs($upperBound, $index/type), $options, $weight)
            else ()
        ))
        else if($index/structure = "xmlattribute")
        then cts:and-query((
            if(exists($lowerBound))
            then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), ">=", common:castAs($lowerBound, $index/type), $options, $weight)
            else (),
            if(exists($upperBound))
            then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), "<", common:castAs($upperBound, $index/type), $options, $weight)
            else ()
        ))
        else ()
};

declare function search:rangeValueToQuery(
    $index as element(index),
    $values as xs:string*
) as cts:query?
{
    search:rangeValueToQuery($index, $values, (), (), ())
};

declare function search:rangeValueToQuery(
    $index as element(index),
    $values as xs:string*,
    $operatorOverride as xs:string?,
    $options as xs:string*,
    $weight as xs:double?
) as cts:query?
{
    let $values :=
        for $value in $values
        let $type :=
            if($index/structure = "xml")
            then string($index/type)
            else if($index/type = "date")
            then "dateTime"
            else if($index/type = "number")
            then "decimal"
            else "string"

        where xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $type, $value)
        return common:castAs($value, $type)
    let $options :=
        if($index/type = "string")
        then ($options, "collation=http://marklogic.com/collation/")
        else $options
    let $JSONQName := xs:QName(concat("json:", $index/key))
    where $index/@type = ("range", "bucketedrange")
    return
        if($index/structure = "json")
        then
            if($index/type = "boolean")
            then cts:element-attribute-range-query($JSONQName, xs:QName("boolean"), "=", $values, $weight)

            else if($index/type = "date")
            then cts:element-attribute-range-query($JSONQName, xs:QName("normalized-date"), common:humanOperatorToMathmatical($index/operator), $values, $weight)

            else cts:element-range-query($JSONQName, common:humanOperatorToMathmatical($index/operator), $values, $options, $weight)
        else if($index/structure = "xmlelement")
        then cts:element-range-query(xs:QName($index/element), common:humanOperatorToMathmatical($index/operator), $values, $options, $weight)

        else if($index/structure = "xmlattribute")
        then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), common:humanOperatorToMathmatical($index/operator), $values, $weight)
        else ()
};

declare function search:mapValueToQuery(
    $index as element(index),
    $value as xs:string
) as cts:query?
{
    (: XXX - would be nice to allow maps for xml attributes :)
    let $QName :=
        if($index/structure = "json")
        then xs:QName(concat("json:", $index/key))
        else if($index/structure = "xmlelement")
        then xs:QName($index/element)
        else ()
    return
        if($index/mode = "equals")
        then
            if($value = ("true", "false"))
            then cts:or-query((
                cts:element-value-query($QName, $value),
                cts:element-attribute-value-query($QName, xs:QName("boolean"), $value)
            ))
            else cts:element-value-query($QName, $value)
        else cts:element-word-query($QName, $value)
};

declare function search:fieldValueToQuery(
    $index as element(index),
    $value as xs:string
) as cts:query?
{
    cts:field-word-query($index/name, $value)
};


declare function search:rangeIndexValues(
    $index as element(index),
    $query as cts:query?,
    $options as xs:string*,
    $limit as xs:positiveInteger
) as xs:string*
{
    let $xsType :=
        if($index/structure = ("xmlelement", "xmlattribute"))
        then string($index/type)
        else if($index/type = "date")
        then "dateTime"
        else if($index/type = "number")
        then "decimal"
        else "string"
    let $options := (
        if(exists($limit))
        then concat("limit=", $limit)
        else (),
        concat("type=", $xsType),
        $options
    )
    where $index/@type = "range"
    return
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:element-attribute-values(xs:QName(concat("json:", json:escapeNCName($index/key))), xs:QName("normalized-date"), (), $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-values(xs:QName(concat("json:", json:escapeNCName($index/key))), (), $options, $query)
            else ()
        else if($index/structure = "xmlelement")
        then cts:element-values(xs:QName($index/element), (), $options, $query)
        else if($index/structure = "xmlattribute")
        then cts:element-attribute-values(xs:QName($index/element), xs:QName($index/attribute), (), $options, $query)
        else ()
};

declare function search:bucketIndexValues(
    $index as element(index),
    $query as cts:query?,
    $options as xs:string*,
    $limit as xs:positiveInteger,
    $valuesInQuery as xs:string*,
    $outputFormat as xs:string
) as element()?
{
    let $xsType :=
        if($index/structure = ("xmlelement", "xmlattribute"))
        then string($index/type)
        else if($index/type = "date")
        then "dateTime"
        else if($index/type = "number")
        then "decimal"
        else "string"
    let $options := (
        if(exists($limit))
        then concat("limit=", $limit)
        else (),
        concat("type=", $xsType),
        $options
    )

    let $buckets := 
        if($index/@type = "bucketedrange")
        then
            for $boundary in $index/buckets/boundary
            where xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, $boundary)
            return common:castAs($boundary, $xsType)
        else if($index/@type = "autobucketedrange")
        then ()
        else ()

    let $values :=
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:element-attribute-value-ranges(xs:QName(concat("json:", json:escapeNCName($index/key))), xs:QName("normalized-date"), $buckets, $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-value-ranges(xs:QName(concat("json:", json:escapeNCName($index/key))), $buckets, $options, $query)
            else ()
        else if($index/structure = "xmlelement")
        then cts:element-value-ranges(xs:QName($index/element), $buckets, $options, $query)
        else if($index/structure = "xmlattribute")
        then cts:element-attribute-value-ranges(xs:QName($index/element), xs:QName($index/attribute), $buckets, $options, $query)
        else ()

    return
        if($outputFormat = "json")
        then json:array(
            for $item at $pos in $values
            let $label := string($index/buckets/label[$pos])
            return json:object((
                "value", $label,
                "inQuery", $label = $valuesInQuery,
                "count", cts:frequency($item)
            ))
        )
        else if($outputFormat = "xml")
        then <facet name="{ $index/@name }">{
            for $item at $pos in $values
            let $log := xdmp:log($item)
            let $label := string($index/buckets/label[$pos])
            return <result>
                <value>{ $label }</value>
                <inQuery>{ $label = $valuesInQuery }</inQuery>
                <count>{ cts:frequency($item) }</count>
            </result>
        }</facet>
        else ()
};
