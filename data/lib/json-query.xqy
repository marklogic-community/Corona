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

module namespace jsonquery="http://marklogic.com/json-query";

import module namespace common="http://marklogic.com/mljson/common" at "common.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function jsonquery:parse(
    $json as xs:string
) as xs:string
{
    let $tree := json:jsonToXML($json)
    let $cts := jsonquery:dispatch($tree/query)
    let $options := jsonquery:extractOptions($tree, "search")
    let $start := jsonquery:extractStartIndex($tree)
    let $end := jsonquery:extractEndIndex($tree)
    let $weight := jsonquery:extractWeight($tree)
    return
        if(exists($start) and exists($end))
        then concat("cts:search(/json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")", "[", $start, " to ", $end, "]")
        else if(exists($start))
        then concat("cts:search(/json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")", "[", $start, "]")
        else concat("cts:search(/json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")")
};

declare function jsonquery:execute(
    $json as xs:string
)
{
    let $tree := json:jsonToXML($json)
    let $cts := jsonquery:dispatch($tree/query)
    let $options := jsonquery:extractOptions($tree, "search")
    let $start := jsonquery:extractStartIndex($tree)
    let $end := jsonquery:extractEndIndex($tree)
    let $weight := jsonquery:extractWeight($tree)
    let $debug :=
        if($tree/debug[@boolean = "true"])
        then (xdmp:log(concat("Constructed search constraint: ", $cts)), xdmp:log(concat("Constructed search options: ", string-join($options, ", "))))
        else ()

    let $results :=
        if(exists($start) and exists($end))
        then cts:search(/json, $cts, $options, $weight)[$start to $end]
        else if(exists($start))
        then cts:search(/json, $cts, $options, $weight)[$start]
        else cts:search(/json, $cts, $options, $weight)

    let $total :=
        if(exists($results[1]))
        then cts:remainder($results[1]) + $start - 1
        else 0

    let $end :=
        if($end > $total)
        then $total
        else $end

    return common:outputMultipleDocs($results, $start, $end, $total)
};

declare private function jsonquery:dispatch(
    $step as element()
)
{
    let $precedent := (
        $step/and[@type = "array"],
        $step/or[@type = "array"],
        $step/not[@type = "object"],
        $step/andNot[@type = "object"],
        $step/property[@type = "object"],
        $step/range[@type = "object"],
        $step/equals[@type = "object"],
        $step/contains[@type = "object"],
        $step/collection[@type = "string"],
        $step/geo[@type = "object"],
        $step/point[@type = "object"],
        $step/circle[@type = "object"],
        $step/box[@type = "object"],
        $step/polygon[@type = "array"]
    )[1]
    return jsonquery:process($precedent)
};

declare private function jsonquery:process(
    $step as element()
)
{
    typeswitch($step)
    case element(item) return jsonquery:dispatch($step)
    case element(and) return cts:and-query(for $item in $step/item[@type = "object"] return jsonquery:process($item))
    case element(or) return cts:or-query(for $item in $step/item[@type = "object"] return jsonquery:process($item))
    case element(not) return cts:not-query(jsonquery:dispatch($step))
    case element(andNot) return jsonquery:handleAndNot($step)
    case element(property) return cts:properties-query(jsonquery:dispatch($step))
    case element(range) return jsonquery:handleRange($step)
    case element(equals) return jsonquery:handleEquals($step)
    case element(contains) return jsonquery:handleContains($step)
    case element(collection) return jsonquery:handleCollection($step)
    case element(geo) return jsonquery:handleGeo($step)
    case element(region) return for $item in $step/item[@type = "object"] return jsonquery:process($item)
    case element(point) return jsonquery:handleGeoPoint($step)
    case element(circle) return jsonquery:handleGeoCircle($step)
    case element(box) return jsonquery:handleGeoBox($step)
    case element(polygon) return jsonquery:handleGeoPolygon($step)
    default return ()
};

declare private function jsonquery:handleAndNot(
    $step as element(andNot)
) as cts:and-not-query?
{
    let $positive := $step/positive[@type = "object"]
    let $negative := $step/negative[@type = "object"]
    where exists($positive) and exists($negative)
    return cts:and-not-query(jsonquery:dispatch($positive), jsonquery:dispatch($negative))
};

declare private function jsonquery:handleRange(
    $step as element(range)
) as cts:query?
{
    if(exists($step/from[@type = "string"]) and exists($step/to[@type = "string"]))
    then
        let $key := $step/key[@type = "string"]
        let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
        let $options := jsonquery:extractOptions($step, "range")
        where exists($key)
        return cts:and-query((
            cts:element-range-query(xs:QName($key), ">=", $step/from, $options, $weight),
            cts:element-range-query(xs:QName($key), "<=", $step/to, $options, $weight)
        ))
    else
        let $key := $step/key[@type = "string"]
        let $operator := ($step/operator[@type = "string"][. = ("=", "!=", "<", ">", "<=", ">=")], "=")[1]
        let $value := jsonquery:stringOrArrayToSet($step/value)
        let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
        where exists($key) and exists($value)
        return cts:element-range-query(xs:QName($key), $operator, $value, jsonquery:extractOptions($step, "range"), $weight)
};

declare private function jsonquery:handleEquals(
    $step as element(equals)
) as cts:element-value-query?
{
    let $key := $step/key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/string)
    let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-value-query(xs:QName($key), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleContains(
    $step as element(contains)
) as cts:element-word-query?
{
    let $key := $step/key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/string)
    let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-word-query(xs:QName($key), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleCollection(
    $step as element(collection)
) as cts:collection-query
{
    cts:collection-query(jsonquery:stringOrArrayToSet($step))
};

declare private function jsonquery:handleGeo(
    $step as element(geo)
) as cts:query?
{
    let $parent := $step/parent[@type = "string"]
    let $key := $step/key[@type = "string"]
    let $latKey := $step/latKey[@type = "string"]
    let $longKey := $step/longKey[@type = "string"]

    let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
    where exists($key) or (exists($latKey) and exists($longKey))
    return
        if(exists($parent) and exists($latKey) and exists($longKey))
        then cts:element-pair-geospatial-query(xs:QName($parent), xs:QName($latKey), xs:QName($longKey), jsonquery:process($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($key))
        then cts:element-child-geospatial-query(xs:QName($parent), xs:QName($key), jsonquery:process($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($key))
        then cts:element-geospatial-query(xs:QName($key), jsonquery:process($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else ()
};

declare private function jsonquery:handleGeoPoint(
    $step as element()
) as cts:point?
{
    if(exists($step/latitude) and exists($step/longitude))
    then cts:point($step/latitude, $step/longitude)
    else ()
};

declare private function jsonquery:handleGeoCircle(
    $step as element(circle)
) as cts:circle?
{
    if(exists($step/radius) and exists($step/latitude) and exists($step/longitude))
    then cts:circle($step/radius, jsonquery:handleGeoPoint($step))
    else ()
};

declare private function jsonquery:handleGeoBox(
    $step as element(box)
) as cts:box
{
    if(exists($step/south) and exists($step/west) and exists($step/north) and exists($step/east))
    then cts:box($step/south, $step/west, $step/north, $step/east)
    else ()
};

declare private function jsonquery:handleGeoPolygon(
    $step as element(polygon)
) as cts:polygon
{
    cts:polygon(
        for $point in $step/item
        return jsonquery:handleGeoPoint($point)
    )
};

declare private function jsonquery:stringOrArrayToSet(
    $item as element()
) as xs:string*
{
    if($item/@type = "string")
    then string($item)
    else
        for $i in $item/item[@type = "string"]
        return string($i)
};

declare private function jsonquery:extractOptions(
    $item as element(),
    $optionSet as xs:string
) as xs:string*
{
    if($optionSet = "word")
    then (
        if(exists($item/caseSensitive))
        then
            if($item/caseSensitive/@boolean = "true")
            then "case-sensitive"
            else "case-insensitive"
        else ()
        ,
        if(exists($item/diacriticSensitive))
        then
            if($item/diacriticSensitive/@boolean = "true")
            then "diacritic-sensitive"
            else "diacritic-insensitive"
        else ()
        ,
        if(exists($item/punctuationSensitve))
        then
            if($item/punctuationSensitve/@boolean = "true")
            then "punctuation-sensitive"
            else "punctuation-insensitive"
        else ()
        ,
        if(exists($item/whitespaceSensitive))
        then
            if($item/whitespaceSensitive/@boolean = "true")
            then "whitespace-sensitive"
            else "whitespace-insensitive"
        else ()
        ,
        if(exists($item/stemmed))
        then
            if($item/stemmed/@boolean = "true")
            then "stemmed"
            else "unstemmed"
        else ()
        ,
        if(exists($item/wildcarded))
        then
            if($item/wildcarded/@boolean = "true")
            then "wildcarded"
            else "unwildcarded"
        else ()
    )
    else ()
    ,
    if($optionSet = ("word", "range"))
    then (
        if(exists($item/minimumOccurances[@type = "number"]))
        then concat("min-occurs=", string($item/minimumOccurances[@type = "number"]))
        else ()
        ,
        if(exists($item/maximumOccurances[@type = "number"]))
        then concat("max-occurs=", string($item/maximumOccurances[@type = "number"]))
        else ()
    )
    else ()
    ,
    if($optionSet = "search")
    then (
        if(exists($item/filtered))
        then
            if($item/filtered/@boolean = "true")
            then "filtered"
            else "unfiltered"
        else ()
        ,
        if(exists($item/score[@type = "string"]))
        then concat("score-", string($item/score[@type = "string"]))
        else ()
    )
    else ()
    ,
    if($optionSet = "search")
    then (
        if(exists($item/coordinateType[@type = "string"]))
        then 
            if($item/coordinateType[@type = "string"] = "long-lat")
            then "type=long-lat-point"
            else "type=point"
        else ()
        ,
        if(exists($item/excludeBoundaries))
        then
            if($item/excludeBoundaries/@boolean = "true")
            then "boundaries-excluded"
            else "boundaries-included"
        else ()
        ,
        if(exists($item/excludeLatitudeBoundaries))
        then
            if($item/excludeLatitudeBoundaries/@boolean = "true")
            then "boundaries-latitude-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeLongitudeBoundaries))
        then
            if($item/excludeLongitudeBoundaries/@boolean = "true")
            then "boundaries-longitude-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeSouthBoundaries))
        then
            if($item/excludeSouthBoundaries/@boolean = "true")
            then "boundaries-south-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeWestBoundaries))
        then
            if($item/excludeWestBoundaries/@boolean = "true")
            then "boundaries-west-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeNorthBoundaries))
        then
            if($item/excludeNorthBoundaries/@boolean = "true")
            then "boundaries-north-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeEastBoundaries))
        then
            if($item/excludeEastBoundaries/@boolean = "true")
            then "boundaries-east-excluded"
            else ()
        else ()
        ,
        if(exists($item/excludeCircleBoundaries))
        then
            if($item/excludeCircleBoundaries/@boolean = "true")
            then "boundaries-circle-excluded"
            else ()
        else ()
    )
    else ()
};

declare private function jsonquery:extractWeight(
    $tree as element(json)
) as xs:double
{
    xs:double(($tree/weight[@type = "number"], 1.0)[1])
};

declare private function jsonquery:extractStartIndex(
    $tree as element(json)
) as xs:integer
{
    if(exists($tree/start) and $tree/start castable as xs:integer)
    then xs:integer($tree/start)
    else 1
};

declare private function jsonquery:extractEndIndex(
    $tree as element(json)
) as xs:integer?
{
    if(exists($tree/end) and $tree/end castable as xs:integer)
    then xs:integer($tree/end)
    else ()
};
