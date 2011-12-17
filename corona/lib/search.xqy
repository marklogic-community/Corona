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

module namespace search="http://marklogic.com/corona/search";

import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "string-query.xqy";
import module namespace structquery="http://marklogic.com/corona/structured-query" at "structured-query.xqy";
import module namespace sqt="http://marklogic.com/corona/structured-query-translator" at "structured-query-translator.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "manage.xqy";

import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";

declare namespace corona="http://marklogic.com/corona";
declare namespace sec="http://marklogic.com/xdmp/security";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function search:bucketLabelToQuery(
    $index as element(index),
    $bucketLabel as xs:string
) as cts:query?
{
    search:bucketLabelToQuery($index, $bucketLabel, ())
};

declare function search:bucketLabelToQuery(
    $index as element(index),
    $bucketLabel as xs:string,
    $options as xs:string*
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
        then ($options, concat("collation=http://marklogic.com/collation/", $index/collation))
        else $options

    return
        if($index/structure = "json")
        then
            if($index/type = "date")
            then cts:and-query((
                if(exists($lowerBound))
                then cts:element-attribute-range-query(common:keyToQName($index/key), xs:QName("normalized-date"), ">=", common:castFromJSONType($lowerBound, "date"), $options)
                else (),
                if(exists($upperBound))
                then cts:element-attribute-range-query(common:keyToQName($index/key), xs:QName("normalized-date"), "<", common:castFromJSONType($upperBound, "date"), $options)
                else ()
            ))
            else cts:and-query((
                if(exists($lowerBound))
                then cts:element-range-query(common:keyToQName($index/key), ">=", common:castFromJSONType($lowerBound, $index/type), $options)
                else (),
                if(exists($upperBound))
                then cts:element-range-query(common:keyToQName($index/key), "<", common:castFromJSONType($upperBound, $index/type), $options)
                else ()
            ))
        else if($index/structure = "xmlelement")
        then cts:and-query((
            if(exists($lowerBound))
            then cts:element-range-query(xs:QName($index/element), ">=", common:castAs($lowerBound, $index/type), $options)
            else (),
            if(exists($upperBound))
            then cts:element-range-query(xs:QName($index/element), "<", common:castAs($upperBound, $index/type), $options)
            else ()
        ))
        else if($index/structure = "xmlattribute")
        then cts:and-query((
            if(exists($lowerBound))
            then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), ">=", common:castAs($lowerBound, $index/type), $options)
            else (),
            if(exists($upperBound))
            then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), "<", common:castAs($upperBound, $index/type), $options)
            else ()
        ))
        else ()
};

declare function search:rangeValueToQuery(
    $index as element(index),
    $values as xs:string*
) as cts:query?
{
    search:rangeValueToQuery($index, $values, "eq", ())
};

declare function search:rangeValueToQuery(
    $index as element(index),
    $values as xs:string*,
    $operator as xs:string,
    $options as xs:string*
) as cts:query?
{
    let $operator := common:humanOperatorToMathmatical($operator)
    let $values :=
        for $value in $values
        let $type :=
            if($index/structure = ("xmlelement", "xmlattribute"))
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
        then ($options, concat("collation=http://marklogic.com/collation/", $index/collation))
        else $options
    let $JSONQName := if(exists($index/key)) then common:keyToQName($index/key) else ()
    where $index/@type = ("range", "bucketedrange", "autobucketedrange")
    return
        if($index/structure = "json")
        then
            if($index/type = "boolean")
            then cts:element-attribute-range-query($JSONQName, xs:QName("boolean"), "=", $values, $options)

            else if($index/type = "date")
            then cts:element-attribute-range-query($JSONQName, xs:QName("normalized-date"), $operator, $values, $options)

            else cts:element-range-query($JSONQName, $operator, $values, $options)
        else if($index/structure = "xmlelement")
        then cts:element-range-query(xs:QName($index/element), $operator, $values, $options)

        else if($index/structure = "xmlattribute")
        then cts:element-attribute-range-query(xs:QName($index/element), xs:QName($index/attribute), $operator, $values, $options)
        else ()
};

declare function search:placeValueToQuery(
    $index as element(index),
    $value as xs:string*
) as cts:query?
{
    search:placeValueToQuery($index, $value, (), ())
};

declare function search:placeValueToQuery(
    $index as element(index),
    $value as xs:string*,
    $options as xs:string*,
    $weight as xs:double?
) as cts:query?
{
    let $queries :=
        for $item in $index/query/*
        return
            if(local-name($item) = "field")
            then cts:field-word-query($item/@name, $value, $options, $weight)
            else if(local-name($item) = "attribute")
            then cts:element-attribute-word-query(xs:QName($item/@element), xs:QName($item/@attribute), $value, $options, $item/@weight)
            else if(local-name($item) = "element")
            then cts:element-word-query(xs:QName($item/@element), $value, $options, $item/@weight)
            else if(local-name($item) = "key")
            then cts:element-word-query(common:keyToQName($item/@key), $value, $options, $item/@weight)
            else if(local-name($item) = "place")
            then search:placeValueToQuery($index, $value, $options, $weight)
            else ()
    where exists($queries)
    return
        if(count($queries) = 1)
        then $queries
        else cts:or-query($queries)

};

declare function search:rangeIndexValues(
    $index as element(index),
    $query as cts:query?,
    $options as xs:string*,
    $limit as xs:positiveInteger,
    $valuesInQuery as xs:string*,
    $outputFormat as xs:string
) as element()*
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
            then cts:element-attribute-values(common:keyToQName($index/key), xs:QName("normalized-date"), (), $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-values(common:keyToQName($index/key), (), $options, $query)
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
        then <corona:facet name="{ $index/@name }">{
            for $item in $values
            return <corona:result>
                <corona:value>{ $item }</corona:value>
                <corona:inQuery>{ $item = $valuesInQuery }</corona:inQuery>
                <corona:count>{ cts:frequency($item) }</corona:count>
            </corona:result>
        }</corona:facet>
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
            then cts:element-attribute-value-ranges(common:keyToQName($index/key), xs:QName("normalized-date"), $buckets, $options, $query)
            else if($index/type = ("string", "number"))
            then cts:element-value-ranges(common:keyToQName($index/key), $buckets, $options, $query)
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
        then <corona:facet name="{ $index/@name }">{
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
            return <corona:result>
                <corona:value>{ $label }</corona:value>
                <corona:inQuery>{ $label = $valuesInQuery }</corona:inQuery>
                <corona:count>{ cts:frequency($item) }</corona:count>
            </corona:result>
        }</corona:facet>
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

declare function search:geoQuery(
    $index as element(index),
    $region as item()?,
    $options as xs:string*,
    $weight as xs:double?
) as cts:query?
{
    if($index/structure = "elementWithAttributes")
    then cts:element-attribute-pair-geospatial-query(xs:QName($index/parentElement), xs:QName($index/latAttribute), xs:QName($index/longAttribute), $region, $options, $weight)
    else if($index/structure = "elementWithChildren")
    then cts:element-pair-geospatial-query(xs:QName($index/parentElement), xs:QName($index/latElement), xs:QName($index/longElement), $region, $options, $weight)
    else if($index/structure = "keyWithChildren")
    then cts:element-pair-geospatial-query(common:keyToQName($index/parentKey), common:keyToQName($index/latKey), common:keyToQName($index/longKey), $region, $options, $weight)
    else if($index/structure = "elementWithChild")
    then cts:element-child-geospatial-query(xs:QName($index/parentElement), xs:QName($index/element), $region, $options, $weight)
    else if($index/structure = "keyWithChild")
    then cts:element-child-geospatial-query(common:keyToQName($index/parentKey), common:keyToQName($index/key), $region, $options, $weight)
    else if($index/structure = "element")
    then cts:element-geospatial-query(xs:QName($index/element), $region, $options, $weight)
    else if($index/structure = "key")
    then cts:element-geospatial-query(common:keyToQName($index/key), $region, $options, $weight)
    else ()
};

declare function search:saveStructuredQuery(
    $name as xs:string,
    $description as xs:string?,
    $query as xs:string,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element(sec:permission)*
) as empty-sequence()
{
    let $uri := search:generateURIForStoredQuery($name)
    let $test := search:validateNamedQueryName($name, "duplicate")
    let $tree := structquery:getParseTree($query)
    let $prefix := if(contains($name, ":")) then substring-before($name, ":") else ()
    let $doc :=
        <corona:storedQuery type="structured" name="{ $name }" description="{ $description }" createdOn="{ current-dateTime() }">
            { if(exists($prefix)) then attribute { "prefix" } { $prefix} else () }
            <corona:original>{
                if(common:xmlOrJSON($query) = "json")
                then $query
                else xdmp:unquote($query, (), ("repair-none", "format-xml"))[1]
            }</corona:original>
            <corona:seralized>{ structquery:getCTS($tree) }</corona:seralized>
        </corona:storedQuery>
    return (
        xdmp:document-insert($uri, $doc, (xdmp:default-permissions(), $permissions), ($const:StoredQueriesCollection, $collections)),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else xdmp:document-set-properties($uri, ())
    )
};

declare function search:saveStringQuery(
    $name as xs:string,
    $description as xs:string?,
    $query as xs:string,
    $collections as xs:string*,
    $properties as element()*,
    $permissions as element(sec:permission)*
) as empty-sequence()
{
    let $uri := search:generateURIForStoredQuery($name)
    let $test := search:validateNamedQueryName($name, "duplicate")
    let $prefix := if(contains($name, ":")) then substring-before($name, ":") else ()
    let $doc :=
        <corona:storedQuery type="string" name="{ $name }" description="{ $description }" createdOn="{ current-dateTime() }">
            { if(exists($prefix)) then attribute { "prefix" } { $prefix} else () }
            <corona:original>{ $query }</corona:original>
            <corona:seralized>{ stringquery:parse($query) }</corona:seralized>
        </corona:storedQuery>
    return (
        xdmp:document-insert($uri, $doc, (xdmp:default-permissions(), $permissions), ($const:StoredQueriesCollection, $collections)),
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else xdmp:document-set-properties($uri, ())
    )
};

declare function search:getStoredQuery(
    $name as xs:string
) as element(corona:storedQuery)
{
    let $test := search:validateNamedQueryName($name, "exists")
    return doc(search:generateURIForStoredQuery($name))/corona:storedQuery
};

declare function search:getStoredQueryCTS(
    $name as xs:string,
    $ignoreRange as xs:string?,
    $useRegisteredQueries as xs:boolean
) as cts:query?
{
    let $query := doc(search:generateURIForStoredQuery($name))/corona:storedQuery
    let $redo :=
        if(exists($ignoreRange))
        then true() (: XXX - Could be a ton less pessimistic here :)
        else not($useRegisteredQueries)
    return
        if($redo)
        then
            if($query/@type = "structured")
            then structquery:getCTS(if(exists($query/corona:original/*)) then sqt:translate($query/corona:original/*) else structquery:getParseTree(string($query/corona:original)), $ignoreRange, $useRegisteredQueries)
            else stringquery:parse(string($query/corona:original))
        else cts:registered-query(cts:register(cts:query($query/corona:seralized/*)), "unfiltered")
};

declare function search:deleteStoredQuery(
    $name as xs:string
) as empty-sequence()
{
    let $test := search:validateNamedQueryName($name, "exists")
    return xdmp:document-delete(search:generateURIForStoredQuery($name))
};

declare function search:storedQueriesWithPrefix(
    $prefix as xs:string
) as element(corona:storedQuery)*
{
    /corona:storedQuery[@prefix = $prefix]
};

declare private function search:generateURIForStoredQuery(
    $name as xs:string
) as xs:string
{
    concat("_/storedQueries/", $name)
};

declare private function search:validateNamedQueryName(
    $name as xs:string,
    $mode as xs:string+
) as empty-sequence()
{
    let $uri := search:generateURIForStoredQuery($name)
    let $test :=
        if(contains($name, ":"))
        then (
            manage:validateNamedQueryPrefix(substring-before($name, ":")) ,
            if(string-length(substring-after($name, ":")) = 0)
            then error(xs:QName("corona:INVALID-NAMED-QUERY-NAME"), "Named queries with a prefix must contain a colon followed by the query name")
            else ()
        )
        else ()
    let $test :=
        if($mode = "exists" and empty(doc($uri)))
        then error(xs:QName("corona:NAMED-QUERY-NOT-FOUND"), concat("The named query '", $name, "' does not exist"))
        else ()
    let $test :=
        if($mode = "duplicate" and exists(doc($uri)))
        then error(xs:QName("corona:NAMED-QUERY-EXISTS"), concat("A named query with the name '", $name, "' already exists"))
        else ()
    return ()
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
