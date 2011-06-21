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

import module namespace json="http://marklogic.com/json" at "json.xqy";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function jsonquery:execute(
    $json as xs:string
) as element(json)*
{
    let $tree := json:jsonToXML($json)/json
    return
        if(exists($tree/fulltext))
        then jsonquery:executeFulltext($tree)
        else xdmp:eval(jsonquery:parsePath($tree))
};

declare function jsonquery:parse(
    $json as xs:string
) as xs:string
{
    let $tree := json:jsonToXML($json)/json
    return
        if(exists($tree/fulltext))
        then jsonquery:parseFulltext($tree)
        else jsonquery:parsePath($tree)
};

declare private function jsonquery:parsePath(
    $tree as element(json)
) as xs:string
{
    let $basicPredicate := jsonquery:processStep($tree)
    let $path :=
        if($basicPredicate != "")
        then concat("/json[", $basicPredicate, "]")
        else "/json"

    let $orPredicate := string-join(
            for $item in $tree/or[@type = "array"]/item
            return jsonquery:processStep($item)
        , " or ")
    let $path :=
        if($orPredicate != "")
        then concat($path, "[", $orPredicate, "]")
        else $path

    let $andPredicate := string-join(
            for $item in $tree/and[@type = "array"]/item
            return jsonquery:processStep($item)
        , " and ")
    let $path :=
        if($andPredicate != "")
        then concat($path, "[", $andPredicate, "]")
        else $path

    let $position := jsonquery:extractPosition($tree)
    return
        if(exists($position))
        then concat("(", $path, ")[", $position, "]")
        else $path
};

declare private function jsonquery:processStep(
    $step as element()
) as xs:string
{
    if($step/@type = "number")
    then string($step)
    else if($step/@type = "string")
    then concat("""", string($step), """")
    else if($step/@type = "object")
    then concat(if(local-name($step) = "json" or local-name($step/..) = ("or", "and")) then "" else "/", jsonquery:generatePredicate($step))
    else ""
};

declare private function jsonquery:generatePredicate(
    $step as element()
) as xs:string
{
    let $key := $step/key[@type = "string"]
    let $innerKey := $step/innerKey[@type = "string"]
    let $key :=
        if(exists($innerKey) and local-name($step) = "json" and empty($key))
        then concat("//", string($innerKey))
        else if(exists($innerKey) and empty($key))
        then concat("/", string($innerKey))
        else $key
    let $value := $step/value
    let $operator := string(($step/comparison, "=")[1])
    return
        if(exists($key) and exists($value))
        then
            if($value/@type = "string")
            then concat(string($key), " ", $operator, " """, string($value), """")
            else if($value/@type = "number")
            then concat(string($key), " ", $operator, " ", string($value))
            else if($value/@type = "array")
            then
                let $bits :=
                    for $item in $value/item
                    where $item/@type = ("string", "number")
                    return jsonquery:processStep($item)
                let $raw := concat(string($key), " = (", string-join($bits,  ", "), ")")
                return
                    if($operator = "!=")
                    then concat("not(", $raw, ")")
                    else $raw
            else if($value/@type = "object")
            then
                if(empty($value//value) and local-name($value/..) = "json")
                then concat("exists(", $key, jsonquery:processStep($value), ")")
                else concat($key, jsonquery:processStep($value))
            else ""
        else if(exists($key) and empty($value) and local-name($key/..) = "json")
        then concat("exists(", $key, ")")
        else if(exists($key) and empty($value))
        then string($key)
        else ""
};


declare private function jsonquery:parseFulltext(
    $tree as element(json)
) as xs:string
{
    let $cts := jsonquery:dispatchFulltextStep($tree/fulltext)
    let $options := jsonquery:extractOptions($tree/fulltext, "search")
    let $position := jsonquery:extractPosition($tree)
    let $weight := jsonquery:extractWeight($tree)
    return
        if(exists($position))
        then concat("cts:search(/json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")", "[", $position, "]")
        else concat("cts:search(/json, ", $cts, ", ", xdmp:describe($options), ", ", $weight, ")")
};

declare private function jsonquery:executeFulltext(
    $tree as element(json)
)
{
    let $cts := jsonquery:dispatchFulltextStep($tree/fulltext)
    let $options := jsonquery:extractOptions($tree/fulltext, "search")
    let $position := jsonquery:extractPosition($tree)
    let $weight := jsonquery:extractWeight($tree)
    let $bits := tokenize($position, " to ")
    let $positionLow := $bits[1]
    let $positionHigh := $bits[2]
    let $debug :=
        if($tree/debug[@boolean = "true"])
        then (xdmp:log(concat("Constructed search constraint: ", $cts)), xdmp:log(concat("Constructed search options: ", string-join($options, ", "))))
        else ()
    return
        if(exists($positionLow) and empty($positionHigh))
        then cts:search(/json, $cts, $options, $weight)[xs:integer($positionLow)]
        else if(exists($positionLow) and exists($positionHigh) and $positionHigh = "last()")
        then cts:search(/json, $cts, $options, $weight)[xs:integer($positionLow) to last()]
        else if(exists($positionLow) and exists($positionHigh))
        then cts:search(/json, $cts, $options, $weight)[xs:integer($positionLow) to xs:integer($positionHigh)]
        else cts:search(/json, $cts, $options, $weight)
};

declare private function jsonquery:dispatchFulltextStep(
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
    return jsonquery:processFulltextStep($precedent)
};

declare private function jsonquery:processFulltextStep(
    $step as element()
)
{
    typeswitch($step)
    case element(item) return jsonquery:dispatchFulltextStep($step)
    case element(and) return cts:and-query(for $item in $step/item[@type = "object"] return jsonquery:processFulltextStep($item))
    case element(or) return cts:or-query(for $item in $step/item[@type = "object"] return jsonquery:processFulltextStep($item))
    case element(not) return cts:not-query(jsonquery:dispatchFulltextStep($step))
    case element(andNot) return jsonquery:handleFulltextAndNot($step)
    case element(property) return cts:properties-query(jsonquery:dispatchFulltextStep($step))
    case element(range) return jsonquery:handleFulltextRange($step)
    case element(equals) return jsonquery:handleFulltextEquals($step)
    case element(contains) return jsonquery:handleFulltextContains($step)
    case element(collection) return jsonquery:handleFulltextCollection($step)
    case element(geo) return jsonquery:handleFulltextGeo($step)
    case element(region) return for $item in $step/item[@type = "object"] return jsonquery:processFulltextStep($item)
    case element(point) return jsonquery:handleFulltextGeoPoint($step)
    case element(circle) return jsonquery:handleFulltextGeoCircle($step)
    case element(box) return jsonquery:handleFulltextGeoBox($step)
    case element(polygon) return jsonquery:handleFulltextGeoPolygon($step)
    default return ()
};

declare private function jsonquery:handleFulltextAndNot(
    $step as element(andNot)
) as cts:and-not-query?
{
    let $positive := $step/positive[@type = "object"]
    let $negative := $step/negative[@type = "object"]
    where exists($positive) and exists($negative)
    return cts:and-not-query(jsonquery:dispatchFulltextStep($positive), jsonquery:dispatchFulltextStep($negative))
};

declare private function jsonquery:handleFulltextRange(
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

declare private function jsonquery:handleFulltextEquals(
    $step as element(equals)
) as cts:element-value-query?
{
    let $key := $step/key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/string)
    let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-value-query(xs:QName($key), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleFulltextContains(
    $step as element(contains)
) as cts:element-word-query?
{
    let $key := $step/key[@type = "string"]
    let $string := jsonquery:stringOrArrayToSet($step/string)
    let $weight := xs:double(($step/weight[@type = "number"], 1.0)[1])
    where exists($key) and exists($string)
    return cts:element-word-query(xs:QName($key), $string, jsonquery:extractOptions($step, "word"), $weight)
};

declare private function jsonquery:handleFulltextCollection(
    $step as element(collection)
) as cts:collection-query
{
    cts:collection-query(jsonquery:stringOrArrayToSet($step))
};

declare private function jsonquery:handleFulltextGeo(
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
        then cts:element-pair-geospatial-query(xs:QName($parent), xs:QName($latKey), xs:QName($longKey), jsonquery:processFulltextStep($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($parent) and exists($key))
        then cts:element-child-geospatial-query(xs:QName($parent), xs:QName($key), jsonquery:processFulltextStep($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else if(exists($key))
        then cts:element-geospatial-query(xs:QName($key), jsonquery:processFulltextStep($step/region), jsonquery:extractOptions($step, "geo"), $weight)
        else ()
};

declare private function jsonquery:handleFulltextGeoPoint(
    $step as element()
) as cts:point?
{
    if(exists($step/latitude) and exists($step/longitude))
    then cts:point($step/latitude, $step/longitude)
    else ()
};

declare private function jsonquery:handleFulltextGeoCircle(
    $step as element(circle)
) as cts:circle?
{
    if(exists($step/radius) and exists($step/latitude) and exists($step/longitude))
    then cts:circle($step/radius, jsonquery:handleFulltextGeoPoint($step))
    else ()
};

declare private function jsonquery:handleFulltextGeoBox(
    $step as element(box)
) as cts:box
{
    if(exists($step/south) and exists($step/west) and exists($step/north) and exists($step/east))
    then cts:box($step/south, $step/west, $step/north, $step/east)
    else ()
};

declare private function jsonquery:handleFulltextGeoPolygon(
    $step as element(polygon)
) as cts:polygon
{
    cts:polygon(
        for $point in $step/item
        return jsonquery:handleFulltextGeoPoint($point)
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
    xs:double(($tree/fulltext/weight[@type = "number"], 1.0)[1])
};

declare private function jsonquery:extractPosition(
    $tree as element(json)
) as xs:string?
{
    let $position := normalize-space($tree/position)
    let $position :=
        if(empty($tree/position) or $position = "1 to last()")
        then ()
        else $position
    let $validatePosition :=
        if(not(jsonquery:validatePosition($position)))
        then error(xs:QName("JSON-INVALID-POSITION"), concat("Invalid position: '", $position, "'. Positions must be either integers, a range of integers (eg: 1 to 10). In place of an integer a position can also use the function 'last()'."))
        else ()
    return $position 
};

declare private function jsonquery:validatePosition(
    $position as xs:string?
) as xs:boolean
{
    if(empty($position) or $position = "1 to last()" or $position castable as xs:integer)
    then true()
    else if(count(tokenize($position, " to ")) > 2)
    then false()
    else count(
        for $bit in tokenize($position, " to ")
        where not($bit = "last()" or $bit castable as xs:integer)
        return 1
    ) = 0
};
