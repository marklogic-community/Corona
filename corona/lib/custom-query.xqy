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

module namespace customquery="http://marklogic.com/corona/custom-query";

import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";
import module namespace search="http://marklogic.com/corona/search" at "search.xqy";
import module namespace config="http://marklogic.com/corona/index-config" at "index-config.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "reststore.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function customquery:getCTS(
    $json as element(json:json)?
) as cts:query?
{
    customquery:getCTS($json, ())
};

declare function customquery:getCTS(
    $json as element(json:json)?,
    $ignoreRange as xs:string?
) as cts:query?
{
    if(exists($json))
    then customquery:dispatch($json, $ignoreRange)
    else ()
};

declare function customquery:getCTSFromParseTree(
    $parseTree as element(json:json),
    $ignoreRange as xs:string?
) as cts:query?
{
    customquery:dispatch($parseTree, $ignoreRange)
};

declare function customquery:searchJSON(
    $json as element(json:json),
    $include as xs:string*,
    $start as xs:positiveInteger?,
    $end as xs:positiveInteger?,
    $extractPath as xs:string?,
    $applyTransform as xs:string?
) as xs:string
{
    let $start := if(empty($start)) then 1 else $start
    let $cts := customquery:dispatch($json, ())
    let $options := customquery:extractOptions($json, "search")
    let $weight := customquery:extractWeight($json)
    let $debug :=
        if($json/json:debug[@boolean = "true"])
        then (xdmp:log(concat("Constructed search constraint: ", $cts)), xdmp:log(concat("Constructed search options: ", string-join($options, ", "))))
        else ()

    let $results :=
        if(exists($start) and exists($end))
        then cts:search(collection($const:JSONCollection)/json:json, $cts, $options, $weight)[$start to $end]
        else if(exists($start))
        then cts:search(collection($const:JSONCollection)/json:json, $cts, $options, $weight)[$start]
        else cts:search(collection($const:JSONCollection)/json:json, $cts, $options, $weight)

    let $total :=
        if(exists($results[1]))
        then cts:remainder($results[1]) + $start - 1
        else 0

    let $end :=
        if($end > $total)
        then $total
        else $end

    return reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $cts, $extractPath, $applyTransform)
};

declare function customquery:searchXML(
    $json as element(json:json),
    $include as xs:string*,
    $start as xs:positiveInteger?,
    $end as xs:positiveInteger?,
    $extractPath as xs:string?,
    $applyTransform as xs:string?
) as element(response)
{
    let $start := if(empty($start)) then 1 else $start
    let $cts := customquery:dispatch($json, ())
    let $options := customquery:extractOptions($json, "search")
    let $weight := customquery:extractWeight($json)
    let $debug :=
        if($json/json:debug[@boolean = "true"])
        then (xdmp:log(concat("Constructed search constraint: ", $cts)), xdmp:log(concat("Constructed search options: ", string-join($options, ", "))))
        else ()

    let $results :=
        if(exists($start) and exists($end))
        then cts:search(collection($const:XMLCollection)/*, $cts, $options, $weight)[$start to $end]
        else if(exists($start))
        then cts:search(collection($const:XMLCollection)/*, $cts, $options, $weight)[$start]
        else cts:search(collection($const:XMLCollection)/*, $cts, $options, $weight)

    let $total :=
        if(exists($results[1]))
        then cts:remainder($results[1]) + $start - 1
        else 0

    let $end :=
        if($end > $total)
        then $total
        else $end

    return reststore:outputMultipleXMLDocs($results, $start, $end, $total, $include, $cts, $extractPath, $applyTransform)
};

declare function customquery:getParseTree(
    $query as xs:string?
) as element(json:json)?
{
    if(empty($query))
    then ()
    else json:parse($query)
};

declare function customquery:valuesForFacet(
    $parseTree as element(json:json),
    $facetName as xs:string
) as xs:string*
{
    for $range in $parseTree//json:range[@type = "object"][json:name = $facetName]
    return string($range/json:value)
};


declare private function customquery:dispatch(
    $step as element(),
    $ignoreRange as xs:string?
)
{
    let $precedent := (
        $step/json:and[@type = "array"],
        $step/json:or[@type = "array"],
        $step/json:not[@type = "object"],
        $step/json:andNot[@type = "object"],
        $step/json:near[@type = "object"],
        $step/json:isNULL[@type = "object"],
        $step/json:keyExists[@type = ("string", "array")],
        $step/json:property[@type = "object"],
        $step/json:range[@type = "object"],
        $step/json:equals[@type = "object"],
        $step/json:contains[@type = "object"],
        $step/json:wordAnywhere[@type = ("string", "array", "object")],
        $step/json:underElement[@type = "object"],
        $step/json:underKey[@type = "object"],
        $step/json:collection[@type = ("string", "array")],
        $step/json:directory[@type = ("string", "array", "object")],
        $step/json:geo[@type = "object"],
        $step/json:point[@type = "object"],
        $step/json:circle[@type = "object"],
        $step/json:box[@type = "object"],
        $step/json:polygon[@type = "array"]
    )[1]
    return customquery:process($precedent, $ignoreRange)
};

declare private function customquery:process(
    $step as element(),
    $ignoreRange as xs:string?
)
{
    typeswitch($step)
    case element(json:item) return customquery:dispatch($step, $ignoreRange)
    case element(json:and) return cts:and-query(for $item in $step/json:item[@type = "object"] return customquery:process($item, $ignoreRange))
    case element(json:or) return cts:or-query(for $item in $step/json:item[@type = "object"] return customquery:process($item, $ignoreRange))
    case element(json:not) return cts:not-query(customquery:dispatch($step, $ignoreRange))
    case element(json:andNot) return customquery:handleAndNot($step, $ignoreRange)
    case element(json:near) return customquery:handleNear($step, $ignoreRange)
    case element(json:isNULL) return customquery:handleIsNULL($step)
    case element(json:keyExists) return customquery:handleKeyExists($step)
    case element(json:property) return cts:properties-query(customquery:dispatch($step, $ignoreRange))
    case element(json:range) return customquery:handleRange($step, $ignoreRange)
    case element(json:equals) return customquery:handleEquals($step)
    case element(json:contains) return customquery:handleContains($step)
    case element(json:wordAnywhere) return customquery:handleWordAnywhere($step)
    case element(json:underElement) return customquery:handleUnderElement($step, $ignoreRange)
    case element(json:underKey) return customquery:handleUnderKey($step, $ignoreRange)
    case element(json:collection) return customquery:handleCollection($step)
    case element(json:directory) return customquery:handleDirectory($step)
    case element(json:geo) return customquery:handleGeo($step)
    case element(json:region) return customquery:handleRegion($step)
    case element(json:point) return customquery:handleGeoPoint($step)
    case element(json:circle) return customquery:handleGeoCircle($step)
    case element(json:box) return customquery:handleGeoBox($step)
    case element(json:polygon) return customquery:handleGeoPolygon($step)
    default return ()
};

declare private function customquery:handleAndNot(
    $step as element(json:andNot),
    $ignoreRange as xs:string?
) as cts:and-not-query?
{
    let $positive := $step/json:positive[@type = "object"]
    let $negative := $step/json:negative[@type = "object"]
    where exists($positive) and exists($negative)
    return cts:and-not-query(customquery:dispatch($positive, $ignoreRange), customquery:dispatch($negative, $ignoreRange))
};

declare private function customquery:handleNear(
    $step as element(json:near),
    $ignoreRange as xs:string?
) as cts:near-query
{
    let $queries := for $item in $step/json:queries/json:item return customquery:dispatch($item, $ignoreRange)
    let $distance := xs:double(($step/json:distance[@type = "number"], 10.0)[1]) 
    let $options :=
        if($step/json:ordered/@boolean = "true")
        then "ordered"
        else if($step/json:ordered/@boolean = "false")
        then "unordered"
        else ()
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    return cts:near-query($queries, $distance, $options, $weight)
};

declare private function customquery:handleIsNULL(
    $step as element(json:isNULL)
) as cts:element-attribute-value-query?
{
    if(exists($step/json:key))
    then
        let $QName := xs:QName(concat("json:", json:escapeNCName($step/json:key)))
        let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
        return cts:element-attribute-value-query($QName, xs:QName("type"), "null", (), $weight)
    else ()
};

declare private function customquery:handleKeyExists(
    $step as element(json:keyExists)
) as cts:element-query?
{
    let $QNames :=
        for $i in customquery:valueToStrings($step)
        return xs:QName(concat("json:", json:escapeNCName($i)))
    return cts:element-query($QNames, cts:and-query(()))
};

declare private function customquery:handleRange(
    $step as element(json:range),
    $ignoreRange as xs:string?
) as cts:query?
{
    let $indexName := $step/json:name[@type = "string"]
    let $index := config:get($indexName)
    let $options := customquery:extractOptions($step, "range")
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where if(exists($ignoreRange)) then $indexName != $ignoreRange else true() and exists($index)
    return
        if($index/@type = ("bucketedrange", "autobucketedrange") and exists($step/json:bucketLabel))
        then search:bucketLabelToQuery($index, string($step/json:bucketLabel), $options, $weight)

        else if(exists($step/json:from) and exists($step/json:to))
        then cts:and-query((
            search:rangeValueToQuery($index, string($step/json:from), "ge", $options, $weight),
            search:rangeValueToQuery($index, string($step/json:to), "le", $options, $weight)
        ))

        else
            let $operator := string($step/json:operator[@type = "string"])
            let $values := 
                if($step/json:value/@type = "array")
                then $step/json:value//json:item
                else $step/json:value
            return search:rangeValueToQuery($index, $values, $operator, $options, $weight)
};

declare private function customquery:handleEquals(
    $step as element(json:equals)
) as cts:query?
{
    let $values := customquery:valueToStrings($step/json:value)
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where exists($values)
    return
        if(exists($step/json:key[@type = "string"]))
        then
            let $key := $step/json:key
            let $castAs := json:castAs($key, true())
            let $values :=
                if($castAs = "date")
                then
                    for $value in $values
                    return string(dateparser:parse($value))
                else $values
            let $QName := xs:QName(concat("json:", json:escapeNCName($key)))
            return 
                if(exists($step/json:value/@boolean) or ($step/json:value/@type = "array" and count($step/json:value/json:item/@boolean) = count($step/json:value/json:item)))
                then cts:element-attribute-value-query($QName, xs:QName("boolean"), $values, customquery:extractOptions($step, "word"), $weight)
                else if($castAs = "date")
                then cts:element-attribute-value-query($QName, xs:QName("normalized-date"), $values, customquery:extractOptions($step, "word"), $weight)
                else cts:element-value-query($QName, $values, customquery:extractOptions($step, "word"), $weight)

        else if(exists($step/json:element[@type = "string"]) and exists($step/json:attribute[@type = "string"]))
        then cts:element-attribute-value-query(xs:QName($step/json:element), xs:QName($step/json:attribute), $values, customquery:extractOptions($step, "word"), $weight)
        else if(exists($step/json:element[@type = "string"]))
        then cts:element-value-query(xs:QName($step/json:element), $values, customquery:extractOptions($step, "word"), $weight)
        else ()
};

declare private function customquery:handleContains(
    $step as element(json:contains)
) as cts:query?
{
    let $values := customquery:valueToStrings($step/json:string)
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where exists($values)
    return
        if(exists($step/json:key[@type = "string"]))
        then cts:element-word-query(xs:QName(concat("json:", json:escapeNCName($step/json:key))), $values, customquery:extractOptions($step, "word"), $weight)
        else if(exists($step/json:element[@type = "string"]) and exists($step/json:attribute[@type = "string"]))
        then cts:element-attribute-word-query(xs:QName($step/json:element), xs:QName($step/json:attribute), $values, customquery:extractOptions($step, "word"), $weight)
        else if(exists($step/json:element[@type = "string"]))
        then cts:element-word-query(xs:QName($step/json:element), $values, customquery:extractOptions($step, "word"), $weight)
        else ()
};

declare private function customquery:handleWordAnywhere(
    $step as element(json:wordAnywhere)
) as cts:word-query?
{
    if($step/@type = "object")
    then cts:word-query(customquery:valueToStrings($step/json:string), customquery:extractOptions($step, "word"), xs:double(($step/json:weight[@type = "number"], 1.0)[1]))
    else cts:word-query(customquery:valueToStrings($step))
};

declare private function customquery:handleUnderKey(
    $step as element(json:underKey),
    $ignoreRange as xs:string?
) as cts:element-query?
{
    let $query :=
        if($step/json:query/@type = "string")
        then string($step/json:query)
        else customquery:dispatch($step/json:query, $ignoreRange)
    where exists($step/json:key)
    return cts:element-query(xs:QName(concat("json:", json:escapeNCName($step/json:key))), $query)
};

declare private function customquery:handleUnderElement(
    $step as element(json:underElement),
    $ignoreRange as xs:string?
) as cts:element-query?
{
    let $query :=
        if($step/json:query/@type = "string")
        then string($step/json:query)
        else customquery:dispatch($step/json:query, $ignoreRange)
    where exists($step/json:element)
    return cts:element-query(xs:QName($step/json:element), $query)
};

declare private function customquery:handleCollection(
    $step as element(json:collection)
) as cts:collection-query
{
    cts:collection-query(customquery:valueToStrings($step))
};

declare private function customquery:handleDirectory(
    $step as element(json:directory)
) as cts:directory-query?
{
    if($step/@type = "string" or $step/@type = "array")
    then cts:directory-query(customquery:valueToStrings($step))
    else if($step/@type = "object")
    then cts:directory-query(customquery:valueToStrings($step/json:uri), if($step/json:descendants/@boolean = "true") then "infinity" else "1")
    else ()
};

declare private function customquery:handleGeo(
    $step as element(json:geo)
) as cts:query?
{
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    let $parent :=
        if(exists($step/json:parentKey[@type = "string"]))
        then xs:QName(concat("json:", json:escapeNCName($step/json:parentKey)))
        else if(exists($step/json:parentElement[@type = "string"]))
        then xs:QName($step/json:parentElement)
        else ()
    let $latLongPair :=
        if(exists($step/json:key[@type = "string"]))
        then xs:QName(concat("json:", json:escapeNCName($step/json:key)))
        else if(exists($step/json:element[@type = "string"]))
        then xs:QName($step/json:element)
        else ()
    let $latKey :=
        if(exists($step/json:latKey[@type = "string"]))
        then xs:QName(concat("json:", json:escapeNCName($step/json:latKey)))
        else if(exists($step/json:latElement[@type = "string"]))
        then xs:QName($step/json:latElement)
        else ()
    let $longKey :=
        if(exists($step/json:longKey[@type = "string"]))
        then xs:QName(concat("json:", json:escapeNCName($step/json:longKey)))
        else if(exists($step/json:longElement[@type = "string"]))
        then xs:QName($step/json:longElement)
        else ()
    let $latAttribute :=
        if(exists($step/json:latAttribute[@type = "string"]))
        then xs:QName($step/json:latAttribute)
        else ()
    let $longAttribute :=
        if(exists($step/json:longAttribute[@type = "string"]))
        then xs:QName($step/json:longAttribute)
        else ()

    return
        if(exists($parent) and exists($latKey) and exists($longKey))
        then cts:element-pair-geospatial-query($parent, $latKey, $longKey, customquery:process($step/json:region, ()), customquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($latLongPair))
        then cts:element-child-geospatial-query($parent, $latLongPair, customquery:process($step/json:region, ()), customquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($latAttribute) and exists($longAttribute))
        then cts:element-attribute-pair-geospatial-query($parent, $latAttribute, $longAttribute, customquery:process($step/json:region, ()), customquery:extractOptions($step, "geo"), $weight)
        else if(exists($latLongPair))
        then cts:element-geospatial-query($latLongPair, customquery:process($step/json:region, ()), customquery:extractOptions($step, "geo"), $weight)
        else ()
};

declare private function customquery:handleRegion(
    $step as element()
)
{
    if($step[@type = "array"])
    then for $item in $step/json:item[@type = "object"] return customquery:process($item, ())
    else customquery:dispatch($step, ())
};

declare private function customquery:handleGeoPoint(
    $step as element()
) as cts:point?
{
    if(exists($step/json:latitude) and exists($step/json:longitude))
    then cts:point($step/json:latitude, $step/json:longitude)
    else ()
};

declare private function customquery:handleGeoCircle(
    $step as element(json:circle)
) as cts:circle?
{
    if(exists($step/json:radius) and exists($step/json:latitude) and exists($step/json:longitude))
    then cts:circle($step/json:radius, customquery:handleGeoPoint($step))
    else ()
};

declare private function customquery:handleGeoBox(
    $step as element(json:box)
) as cts:box
{
    if(exists($step/json:south) and exists($step/json:west) and exists($step/json:north) and exists($step/json:east))
    then cts:box($step/json:south, $step/json:west, $step/json:north, $step/json:east)
    else ()
};

declare private function customquery:handleGeoPolygon(
    $step as element(json:polygon)
) as cts:polygon
{
    cts:polygon(
        for $point in $step/json:item
        return customquery:handleGeoPoint($point)
    )
};

declare private function customquery:valueToStrings(
    $item as element()
) as xs:string*
{
    if($item/@type = "array")
    then
        for $i in $item/json:item
        return customquery:valueToStrings($i)
    else if(exists($item/@boolean))
    then string($item/@boolean)
    else if($item/@type = "object")
    then ()
    else string($item)
};

declare private function customquery:extractOptions(
    $item as element(),
    $optionSet as xs:string
) as xs:string*
{
    if($optionSet = "word")
    then (
        if(exists($item/json:caseSensitive))
        then
            if($item/json:caseSensitive/@boolean = "true")
            then "case-sensitive"
            else "case-insensitive"
        else ()
        ,
        if(exists($item/json:diacriticSensitive))
        then
            if($item/json:diacriticSensitive/@boolean = "true")
            then "diacritic-sensitive"
            else "diacritic-insensitive"
        else ()
        ,
        if(exists($item/json:punctuationSensitve))
        then
            if($item/json:punctuationSensitve/@boolean = "true")
            then "punctuation-sensitive"
            else "punctuation-insensitive"
        else ()
        ,
        if(exists($item/json:whitespaceSensitive))
        then
            if($item/json:whitespaceSensitive/@boolean = "true")
            then "whitespace-sensitive"
            else "whitespace-insensitive"
        else ()
        ,
        if(exists($item/json:stemmed))
        then
            if($item/json:stemmed/@boolean = "true")
            then "stemmed"
            else "unstemmed"
        else ()
        ,
        if(exists($item/json:wildcarded))
        then
            if($item/json:wildcarded/@boolean = "true")
            then "wildcarded"
            else "unwildcarded"
        else ()
        ,
        if($item/json:exact/@boolean = "true")
        then "exact"
        else ()
    )
    else ()
    ,
    if($optionSet = ("word", "range"))
    then (
        if(exists($item/json:minimumOccurances[@type = "number"]))
        then concat("min-occurs=", string($item/json:minimumOccurances[@type = "number"]))
        else ()
        ,
        if(exists($item/json:maximumOccurances[@type = "number"]))
        then concat("max-occurs=", string($item/json:maximumOccurances[@type = "number"]))
        else ()
    )
    else ()
    ,
    if($optionSet = "search")
    then (
        if(exists($item/json:filtered))
        then
            if($item/json:filtered/@boolean = "true")
            then "filtered"
            else "unfiltered"
        else ()
        ,
        if(exists($item/json:score[@type = "string"]))
        then concat("score-", string($item/json:score[@type = "string"]))
        else ()
    )
    else ()
    ,
    if($optionSet = "geo")
    then (
        if(exists($item/json:coordinateType[@type = "string"]))
        then 
            if($item/json:coordinateType[@type = "string"] = "long-lat")
            then "type=long-lat-point"
            else "type=point"
        else ()
        ,
        if(exists($item/json:excludeBoundaries))
        then
            if($item/json:excludeBoundaries/@boolean = "true")
            then "boundaries-excluded"
            else "boundaries-included"
        else ()
        ,
        if(exists($item/json:excludeLatitudeBoundaries))
        then
            if($item/excludeLatitudeBoundaries/@boolean = "true")
            then "boundaries-latitude-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeLongitudeBoundaries))
        then
            if($item/json:excludeLongitudeBoundaries/@boolean = "true")
            then "boundaries-longitude-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeSouthBoundaries))
        then
            if($item/json:excludeSouthBoundaries/@boolean = "true")
            then "boundaries-south-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeWestBoundaries))
        then
            if($item/json:excludeWestBoundaries/@boolean = "true")
            then "boundaries-west-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeNorthBoundaries))
        then
            if($item/json:excludeNorthBoundaries/@boolean = "true")
            then "boundaries-north-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeEastBoundaries))
        then
            if($item/json:excludeEastBoundaries/@boolean = "true")
            then "boundaries-east-excluded"
            else ()
        else ()
        ,
        if(exists($item/json:excludeCircleBoundaries))
        then
            if($item/json:excludeCircleBoundaries/@boolean = "true")
            then "boundaries-circle-excluded"
            else ()
        else ()
    )
    else ()
};

declare private function customquery:extractWeight(
    $tree as element(json:json)
) as xs:double
{
    xs:double(($tree/json:weight[@type = "number"], 1.0)[1])
};
