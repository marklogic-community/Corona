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
        then concat("cts:search(/json:json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")", "[", $start, " to ", $end, "]")
        else if(exists($start))
        then concat("cts:search(/json:json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")", "[", $start, "]")
        else concat("cts:search(/json:json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")")
};

declare function jsonquery:execute(
    $json as xs:string,
    $include as xs:string*
) as xs:string
{
    let $tree := json:jsonToXML($json)
    let $cts := jsonquery:dispatch($tree/json:query)
    let $options := jsonquery:extractOptions($tree, "search")
    let $start := jsonquery:extractStartIndex($tree)
    let $end := jsonquery:extractEndIndex($tree)
    let $weight := jsonquery:extractWeight($tree)
    let $debug :=
        if($tree/json:debug[@boolean = "true"])
        then (xdmp:log(concat("Constructed search constraint: ", $cts)), xdmp:log(concat("Constructed search options: ", string-join($options, ", "))))
        else ()

    let $results :=
        if(exists($start) and exists($end))
        then cts:search(/json:json, $cts, $options, $weight)[$start to $end]
        else if(exists($start))
        then cts:search(/json:json, $cts, $options, $weight)[$start]
        else cts:search(/json:json, $cts, $options, $weight)

    let $total :=
        if(exists($results[1]))
        then cts:remainder($results[1]) + $start - 1
        else 0

    let $end :=
        if($end > $total)
        then $total
        else $end

    return common:outputMultipleDocs($results, $start, $end, $total, $include, $cts)
};

declare private function jsonquery:dispatch(
    $step as element()
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
    return jsonquery:process($precedent)
};

declare private function jsonquery:process(
    $step as element()
)
{
    typeswitch($step)
    case element(json:item) return jsonquery:dispatch($step)
    case element(json:and) return cts:and-query(for $item in $step/json:item[@type = "object"] return jsonquery:process($item))
    case element(json:or) return cts:or-query(for $item in $step/json:item[@type = "object"] return jsonquery:process($item))
    case element(json:not) return cts:not-query(jsonquery:dispatch($step))
    case element(json:andNot) return jsonquery:handleAndNot($step)
    case element(json:property) return cts:properties-query(jsonquery:dispatch($step))
    case element(json:range) return jsonquery:handleRange($step)
    case element(json:equals) return jsonquery:handleEquals($step)
    case element(json:contains) return jsonquery:handleContains($step)
    case element(json:collection) return jsonquery:handleCollection($step)
    case element(json:geo) return jsonquery:handleGeo($step)
    case element(json:region) return for $item in $step/json:item[@type = "object"] return jsonquery:process($item)
    case element(json:point) return jsonquery:handleGeoPoint($step)
    case element(json:circle) return jsonquery:handleGeoCircle($step)
    case element(json:box) return jsonquery:handleGeoBox($step)
    case element(json:polygon) return jsonquery:handleGeoPolygon($step)
    default return ()
};

declare private function jsonquery:handleAndNot(
    $step as element(json:andNot)
) as cts:and-not-query?
{
    let $positive := $step/json:positive[@type = "object"]
    let $negative := $step/json:negative[@type = "object"]
    where exists($positive) and exists($negative)
    return cts:and-not-query(jsonquery:dispatch($positive), jsonquery:dispatch($negative))
};

declare private function jsonquery:handleRange(
    $step as element(json:range)
) as cts:query?
{
    if(exists($step/json:from[@type = "string"]) and exists($step/json:to[@type = "string"]))
    then
        let $key := $step/json:key[@type = "string"]
        let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
        let $options := jsonquery:extractOptions($step, "range")
        where exists($key)
        return cts:and-query((
            cts:element-range-query(xs:QName(concat("json:", $key)), ">=", $step/json:from, $options, $weight),
            cts:element-range-query(xs:QName(concat("json:", $key)), "<=", $step/json:to, $options, $weight)
        ))
    else
        let $key := $step/json:key[@type = "string"]
        let $operator := ($step/json:operator[@type = "string"][. = ("=", "!=", "<", ">", "<=", ">=")], "=")[1]
        let $value := jsonquery:stringOrArrayToSet($step/json:value)
        let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
        where exists($key) and exists($value)
        return cts:element-range-query(xs:QName(concat("json:", $key)), $operator, $value, jsonquery:extractOptions($step, "range"), $weight)
};

declare private function jsonquery:handleEquals(
    $step as element(json:equals)
) as cts:element-value-query?
{
    let $key := $step/json:key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/json:string)
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-value-query(xs:QName(concat("json:", $key)), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleContains(
    $step as element(json:contains)
) as cts:element-word-query?
{
    let $key := $step/json:key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/json:string)
    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-word-query(xs:QName(concat("json:", $key)), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleCollection(
    $step as element(json:collection)
) as cts:collection-query
{
    cts:collection-query(jsonquery:stringOrArrayToSet($step))
};

declare private function jsonquery:handleGeo(
    $step as element(json:geo)
) as cts:query?
{
    let $parent := $step/json:parent[@type = "string"]
    let $key := $step/json:key[@type = "string"]
    let $latKey := $step/json:latKey[@type = "string"]
    let $longKey := $step/json:longKey[@type = "string"]

    let $weight := xs:double(($step/json:weight[@type = "number"], 1.0)[1])
    where exists($key) or (exists($latKey) and exists($longKey))
    return
        if(exists($parent) and exists($latKey) and exists($longKey))
        then cts:element-pair-geospatial-query(xs:QName(concat("json:", $parent)), xs:QName(concat("json:", $latKey)), xs:QName(concat("json:", $longKey)), jsonquery:process($step/json:region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($key))
        then cts:element-child-geospatial-query(xs:QName(concat("json:", $parent)), xs:QName(concat("json:", $key)), jsonquery:process($step/json:region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($key))
        then cts:element-geospatial-query(xs:QName(concat("json:", $key)), jsonquery:process($step/json:region), jsonquery:extractOptions($step, "geo"), $weight)
        else ()
};

declare private function jsonquery:handleGeoPoint(
    $step as element()
) as cts:point?
{
    if(exists($step/json:latitude) and exists($step/json:longitude))
    then cts:point($step/json:latitude, $step/json:longitude)
    else ()
};

declare private function jsonquery:handleGeoCircle(
    $step as element(json:circle)
) as cts:circle?
{
    if(exists($step/json:radius) and exists($step/json:latitude) and exists($step/json:longitude))
    then cts:circle($step/json:radius, jsonquery:handleGeoPoint($step))
    else ()
};

declare private function jsonquery:handleGeoBox(
    $step as element(json:box)
) as cts:box
{
    if(exists($step/json:south) and exists($step/json:west) and exists($step/json:north) and exists($step/json:east))
    then cts:box($step/json:south, $step/json:west, $step/json:north, $step/json:east)
    else ()
};

declare private function jsonquery:handleGeoPolygon(
    $step as element(json:polygon)
) as cts:polygon
{
    cts:polygon(
        for $point in $step/json:item
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
        for $i in $item/json:item[@type = "string"]
        return string($i)
};

declare private function jsonquery:extractOptions(
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
    if($optionSet = "search")
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

declare private function jsonquery:extractWeight(
    $tree as element(json:json)
) as xs:double
{
    xs:double(($tree/json:weight[@type = "number"], 1.0)[1])
};

declare private function jsonquery:extractStartIndex(
    $tree as element(json:json)
) as xs:integer
{
    if(exists($tree/json:start) and $tree/json:start castable as xs:integer)
    then xs:integer($tree/json:start)
    else 1
};

declare private function jsonquery:extractEndIndex(
    $tree as element(json:json)
) as xs:integer?
{
    if(exists($tree/json:end) and $tree/json:end castable as xs:integer)
    then xs:integer($tree/json:end)
    else ()
};
