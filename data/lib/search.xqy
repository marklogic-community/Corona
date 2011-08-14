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
    let $bounds :=
        if($index/@type = "bucketedrange")
        then
            let $bucketBits := $index/buckets/*
            let $positionOfBucketLabel :=
                for $bucket at $pos in $bucketBits
                where local-name($bucket) = "label" and string($bucket) = $bucketLabel
                return $pos
            return (
                if($positionOfBucketLabel > 1)
                then <lower>{ $bucketBits[$positionOfBucketLabel - 1] }</lower>
                else (),
                if($positionOfBucketLabel < count($bucketBits))
                then <upper>{ $bucketBits[$positionOfBucketLabel + 1] }</upper>
                else ()
            )
        else
            let $buckets := search:getBucketsForIndex($index)
            let $numBuckets := count($buckets)
            for $pos in (0 to $numBuckets)
            let $bucket := $buckets[$pos]
            let $thisBucketLabel :=
                if($pos = 0)
                then xdmp:strftime($index/firstFormat, $buckets[1])
                else if($pos = $numBuckets)
                then xdmp:strftime($index/lastFormat, $bucket)
                else common:dualStrftime($index/format, $bucket, $buckets[$pos + 1])
            where $thisBucketLabel = $bucketLabel
            return
                if($pos = 0)
                then <upper>{ $buckets[1] }</upper>
                else if($pos = $numBuckets)
                then <lower>{ $bucket }</lower>
                else (<lower>{ $bucket }</lower>, <upper>{ $buckets[$pos + 1] }</upper>)

    let $lowerBound := $bounds[local-name(.) = "lower"]
    let $upperBound := $bounds[local-name(.) = "upper"]

    let $options :=
        if($index/type = "string")
        then ($options, "collation=http://marklogic.com/collation/")
        else $options

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
    let $operatorOverride :=
        if(string-length($operatorOverride))
        then $operatorOverride
        else ()
    let $operator := common:humanOperatorToMathmatical(($operatorOverride, string($index/operator))[1])
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

        where $type = "dateTime" or xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $type, $value)
        return common:castAs($value, $type)
    let $options :=
        if($index/type = "string")
        then ($options, "collation=http://marklogic.com/collation/")
        else $options
    let $JSONQName := if(exists($index/key)) then xs:QName(concat("json:", $index/key)) else ()
    where $index/@type = ("range", "bucketedrange", "autobucketedrange")
    return
        if($index/structure = "json")
        then
            if($index/type = "boolean")
            then cts:element-attribute-range-query($JSONQName, xs:QName("boolean"), "=", $values, $options, $weight)

            else if($index/type = "date")
            then cts:element-attribute-range-query($JSONQName, xs:QName("normalized-date"), $operator, $values, $options, $weight)

            else cts:element-range-query($JSONQName, $operator, $values, $options, $weight)
        else if($index/structure = "xmlelement")
        then cts:element-range-query(xs:QName($index/element), $operator, $values, $options, $weight)

        else if($index/structure = "xmlattribute")
        then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), $operator, $values, $options, $weight)
        else ()
};

declare function search:mapValueToQuery(
    $index as element(index),
    $value as xs:string
) as cts:query?
{
    let $QName :=
        if($index/structure = "json")
        then xs:QName(concat("json:", $index/key))
        else if($index/structure = "xmlelement")
        then xs:QName($index/element)
        else ()
    let $options :=
        if($index/mode = "equals")
        then "exact"
        else (
            "case-insensitive", 
            "punctuation-insensitive",
            "whitespace-insensitive"
        )
    return
        if($index/structure = "xmlattribute")
        then
            if($index/mode = ("equals", "textEquals"))
            then cts:element-attribute-value-query($QName, xs:QName($index/attribute), $value, $options)
            else cts:element-attribute-word-query($QName, xs:QName($index/attribute), $value, $options)
        else
            if($index/mode = "equals")
            then
                if($value = ("true", "false"))
                then cts:or-query((
                    cts:element-value-query($QName, $value, $options),
                    cts:element-attribute-value-query($QName, xs:QName("boolean"), $value, $options)
                ))
                else cts:element-value-query($QName, $value, $options)
            else cts:element-word-query($QName, $value, $options)
};

declare function search:fieldValueToQuery(
    $index as element(index),
    $value as xs:string
) as cts:query?
{
    cts:field-word-query($index/@name, $value)
};


declare function search:rangeIndexValues(
    $index as element(index),
    $query as cts:query?,
    $options as xs:string*,
    $limit as xs:positiveInteger,
    $valuesInQuery as xs:string*,
    $outputFormat as xs:string
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
    let $values :=
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:element-attribute-values(xs:QName(concat("json:", $index/key)), xs:QName("normalized-date"), (), $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-values(xs:QName(concat("json:", $index/key)), (), $options, $query)
            else ()
        else if($index/structure = "xmlelement")
        then cts:element-values(xs:QName($index/element), (), $options, $query)
        else if($index/structure = "xmlattribute")
        then cts:element-attribute-values(xs:QName($index/element), xs:QName($index/attribute), (), $options, $query)
        else ()
    return
        if($outputFormat = "json")
        then json:array(
            for $item in $values
            return json:object((
                "value", $item,
                "inQuery", $item = $valuesInQuery,
                "count", cts:frequency($item)
            ))
        )
        else if($outputFormat = "xml")
        then <facet name="{ $index/@name }">{
            for $item in $values
            return <result>
                <value>{ $item }</value>
                <inQuery>{ $item = $valuesInQuery }</inQuery>
                <count>{ cts:frequency($item) }</count>
            </result>
        }</facet>
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

    let $buckets := search:getBucketsForIndex($index)
    let $values :=
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:element-attribute-value-ranges(xs:QName(concat("json:", $index/key)), xs:QName("normalized-date"), $buckets, $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-value-ranges(xs:QName(concat("json:", $index/key)), $buckets, $options, $query)
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
            let $label :=
                if($index/@type = "autobucketedrange")
                then
                    if(exists($item/cts:lower-bound) and exists($item/cts:upper-bound))
                    then common:dualStrftime($index/format, $item/cts:lower-bound, $item/cts:upper-bound)
                    else if(exists($item/cts:upper-bound))
                    then xdmp:strftime($index/firstFormat, $item/cts:upper-bound)
                    else if(exists($item/cts:lower-bound))
                    then xdmp:strftime($index/lastFormat, $item/cts:lower-bound)
                    else ()
                else search:getLabelForBounds($index, $item/cts:lower-bound, $item/cts:upper-bound)
            return json:object((
                "value", $label,
                "inQuery", $label = $valuesInQuery,
                "count", cts:frequency($item)
            ))
        )
        else if($outputFormat = "xml")
        then <facet name="{ $index/@name }">{
            for $item at $pos in $values
            let $label :=
                if($index/@type = "autobucketedrange")
                then
                    if(exists($item/cts:lower-bound) and exists($item/cts:upper-bound))
                    then common:dualStrftime($index/format, $item/cts:lower-bound, $item/cts:upper-bound)
                    else if(exists($item/cts:upper-bound))
                    then xdmp:strftime($index/firstFormat, $item/cts:upper-bound)
                    else if(exists($item/cts:lower-bound))
                    then xdmp:strftime($index/lastFormat, $item/cts:lower-bound)
                    else ()
                else search:getLabelForBounds($index, $item/cts:lower-bound, $item/cts:upper-bound)
            return <result>
                <value>{ $label }</value>
                <inQuery>{ $label = $valuesInQuery }</inQuery>
                <count>{ cts:frequency($item) }</count>
            </result>
        }</facet>
        else ()
};

declare function search:getBucketsForIndex(
    $index as element(index)
) as xs:anySimpleType*
{
    if($index/@type = "bucketedrange")
    then
        let $xsType :=
            if($index/structure = ("xmlelement", "xmlattribute"))
            then string($index/type)
            else if($index/type = "date")
            then "dateTime"
            else if($index/type = "number")
            then "decimal"
            else "string"
        for $boundary in $index/buckets/boundary
        where xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, $boundary)
        return common:castAs($boundary, $xsType)
    else if($index/@type = "autobucketedrange")
    then 
        let $duration :=
            if($index/bucketInterval = "decade")
            then xs:yearMonthDuration("P10Y")
            else if($index/bucketInterval = "year")
            then xs:yearMonthDuration("P1Y")
            else if($index/bucketInterval = "quarter")
            then xs:yearMonthDuration("P3M")
            else if($index/bucketInterval = "month")
            then xs:yearMonthDuration("P1M")
            else if($index/bucketInterval = "week")
            then xs:dayTimeDuration("P7D")
            else if($index/bucketInterval = "day")
            then xs:dayTimeDuration("P1D")
            else if($index/bucketInterval = "hour")
            then xs:dayTimeDuration("PT1H")
            else if($index/bucketInterval = "minute")
            then xs:dayTimeDuration("PT1M")
            else ()
        let $startDate := xs:dateTime($index/startingAt)
        let $stopDate :=
            if(exists($index/stoppingAt))
            then xs:dateTime($index/stoppingAt)
            else current-dateTime()
        return search:generateDatesWithInterval($startDate, $duration, $stopDate)
    else ()
};

declare private function search:generateDatesWithInterval(
    $startDate as xs:dateTime,
    $interval as xs:duration,
    $endDate as xs:dateTime
) as xs:dateTime*
{
    let $latestDate := $startDate
    for $i in (1 to 100)
    where $latestDate le $endDate
    return (
        adjust-dateTime-to-timezone($latestDate, ()),
        xdmp:set($latestDate, $latestDate + $interval),
        if($i = 100 and $latestDate < $endDate)
        then search:generateDatesWithInterval($latestDate, $interval, $endDate)
        else ()
    )
};

declare private function search:getLabelForBounds(
    $index as element(index),
    $lowerBound as xs:anySimpleType?,
    $upperBound as xs:anySimpleType?
) as xs:string?
{
    if(empty($lowerBound) and string($upperBound) = ($index/buckets/boundary)[1])
    then string(($index/buckets/label)[1])
    else if(empty($upperBound) and string($lowerBound) = ($index/buckets/boundary)[last()])
    then string(($index/buckets/label)[last()])
    else
        let $bits := $index/buckets/*
        for $bucketBit at $pos in $bits
        where local-name($bucketBit) = "boundary" and string($lowerBound) = $bucketBit and string($upperBound) = $bits[$pos + 2]
        return $bits[$pos + 1]
};
