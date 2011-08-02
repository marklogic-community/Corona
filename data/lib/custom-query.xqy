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

module namespace customquery="http://marklogic.com/mljson/custom-query";

import module namespace const="http://marklogic.com/mljson/constants" at "constants.xqy";
import module namespace search="http://marklogic.com/mljson/search" at "search.xqy";
import module namespace config="http://marklogic.com/mljson/index-config" at "index-config.xqy";
import module namespace common="http://marklogic.com/mljson/common" at "common.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "reststore.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function customquery:getCTS(
    $json as xs:string,
    $ignoreRange as xs:string?
) as cts:query
{
    let $tree := json:jsonToXML($json)
    return customquery:dispatch($tree, $ignoreRange)
};

declare function customquery:searchJSON(
    $json as xs:string,
    $include as xs:string*,
    $start as xs:positiveInteger?,
    $end as xs:positiveInteger?,
    $returnPath as xs:string?
) as xs:string
{
    let $start := if(empty($start)) then 1 else $start
    let $tree := json:jsonToXML($json)
    let $cts := customquery:dispatch($tree, ())
    let $options := customquery:extractOptions($tree, "search")
    let $weight := customquery:extractWeight($tree)
    let $debug :=
        if($tree/json:debug[@boolean = "true"])
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

    return reststore:outputMultipleJSONDocs($results, $start, $end, $total, $include, $cts, $returnPath)
};

declare function customquery:searchXML(
    $json as xs:string,
    $include as xs:string*,
    $start as xs:positiveInteger?,
    $end as xs:positiveInteger?,
    $returnPath as xs:string?
) as element(response)
{
    let $start := if(empty($start)) then 1 else $start
    let $tree := json:jsonToXML($json)
    let $cts := customquery:dispatch($tree, ())
    let $options := customquery:extractOptions($tree, "search")
    let $weight := customquery:extractWeight($tree)
    let $debug :=
        if($tree/json:debug[@boolean = "true"])
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

    return reststore:outputMultipleXMLDocs($results, $start, $end, $total, $include, $cts, $returnPath)
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
        $step/json:property[@type = "object"],
        $step/json:range[@type = "object"],
        $step/json:equals[@type = "object"],
        $step/json:contains[@type = "object"],
        $step/json:collection[@type = "string"],
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
    case element(json:property) return cts:properties-query(customquery:dispatch($step, $ignoreRange))
    case element(json:range) return customquery:handleRange($step, $ignoreRange)
    case element(json:equals) return customquery:handleEquals($step)
    case element(json:contains) return customquery:handleContains($step)
    case element(json:collection) return customquery:handleCollection($step)
    case element(json:geo) return customquery:handleGeo($step, $ignoreRange)
    case element(json:region) return for $item in $step/json:item[@type = "object"] return customquery:process($item, $ignoreRange)
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

declare private function customquery:handleRange(
    $step as element(json:range),
    $ignoreRange as xs:string?
) as cts:query?
{
    let $indexName := $step/json:name[@type = "string"]
    let $index := config:get($indexName)
    let $options := customquery:extractOptions($step, "range")
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where $indexName != $ignoreRange and exists($index)
    return
        if($index/@type = "bucketedrange" and exists($step/json:bucketLabel))
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

declare private function customquery:handleCollection(
    $step as element(json:collection)
) as cts:collection-query
{
    cts:collection-query(customquery:valueToStrings($step))
};

declare private function customquery:handleGeo(
    $step as element(json:geo),
    $ignoreRange as xs:string?
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

    where exists($latLongPair) or (exists($latKey) and exists($longKey))
    return
        if(exists($parent) and exists($latKey) and exists($longKey))
        then cts:element-pair-geospatial-query($parent, $latKey, $longKey, customquery:process($step/json:region, $ignoreRange), customquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($latLongPair))
        then cts:element-child-geospatial-query($parent, $latLongPair, customquery:process($step/json:region, $ignoreRange), customquery:extractOptions($step, "geo"), $weight)
        else if(exists($latLongPair))
        then cts:element-geospatial-query($latLongPair, customquery:process($step/json:region, $ignoreRange), customquery:extractOptions($step, "geo"), $weight)
        else ()
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
