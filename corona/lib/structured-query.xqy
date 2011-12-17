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

module namespace structquery="http://marklogic.com/corona/structured-query";

import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace sqt="http://marklogic.com/corona/structured-query-translator" at "structured-query-translator.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";
import module namespace stringquery="http://marklogic.com/corona/string-query" at "string-query.xqy";
import module namespace search="http://marklogic.com/corona/search" at "search.xqy";
import module namespace config="http://marklogic.com/corona/index-config" at "index-config.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace store="http://marklogic.com/corona/store" at "store.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare namespace corona="http://marklogic.com/corona";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function structquery:getCTS(
    $json as element(json:json)?
) as cts:query?
{
    structquery:getCTS($json, (), true())
};

declare function structquery:getCTS(
    $json as element(json:json)?,
    $ignoreRange as xs:string?
) as cts:query?
{
    structquery:getCTS($json, $ignoreRange, true())
};

declare function structquery:getCTS(
    $json as element(json:json)?,
    $ignoreRange as xs:string?,
    $useRegisteredQueries as xs:boolean
) as cts:query?
{
    if(exists($json))
    then structquery:dispatch($json, $ignoreRange, $useRegisteredQueries)
    else ()
};

declare function structquery:getCTSFromParseTree(
    $parseTree as element(json:json)
) as cts:query?
{
    structquery:getCTSFromParseTree($parseTree, (), true())
};

declare function structquery:getCTSFromParseTree(
    $parseTree as element(json:json),
    $ignoreRange as xs:string?
) as cts:query?
{
    structquery:getCTSFromParseTree($parseTree, $ignoreRange, true())
};

declare function structquery:getCTSFromParseTree(
    $parseTree as element(json:json),
    $ignoreRange as xs:string?,
    $useRegisteredQueries as xs:boolean
) as cts:query?
{
    structquery:dispatch($parseTree, $ignoreRange, $useRegisteredQueries)
};

declare function structquery:getParseTree(
    $query as xs:string?
) as element(json:json)?
{
    if(empty($query))
    then ()
    else if(common:xmlOrJSON($query) = "xml")
    then sqt:translate(xdmp:unquote($query)/*)
    else json:parse($query)
};

declare function structquery:valuesForFacet(
    $parseTree as element(json:json),
    $facetName as xs:string
) as xs:string*
{
    for $range in $parseTree//json:range[@type = "object"][json:name = $facetName]
    return string($range/json:value)
};

declare function structquery:containsNamedQuery(
    $json as element(json:json)?
) as xs:boolean
{
    exists($json//json:namedQuery)
};


declare private function structquery:dispatch(
    $step as element(),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
)
{
    let $precedent := (
        $step/json:and[@type = "array"],
        $step/json:or[@type = "array"],
        $step/json:not[@type = "object"],
        $step/json:andNot[@type = "object"],
        $step/json:near[@type = "array"],
        $step/json:isNULL[@type = "string"],
        $step/json:keyExists[@type = ("string", "array")],
        $step/json:elementExists[@type = ("string", "array")],
        $step/json:underElement[@type = "string"],
        $step/json:underKey[@type = "string"],
        $step/json:boolean[exists(@boolean)],

        $step/json:key[@type = "string"],
        $step/json:element[@type = "string"],
        $step/json:property[@type = "string"],
        $step/json:place[@type = "string"],
        $step/json:range[@type = "string"],
        $step/json:collection[@type = ("string", "array")],
        $step/json:directory[@type = ("string", "array")],
        $step/json:stringQuery[@type = "string"],
        $step/json:namedQuery[@type = "string"],
        $step/json:wordAnywhere[@type = ("string", "array")],
        $step/json:wordInBinary[@type = ("string", "array")],
        $step/json:inTextDocument[@type = ("string", "array")],
        $step/json:contentType[@type = "string"],

        $step/json:geo[@type = "string"],
        $step/json:point[@type = "object"],
        $step/json:circle[@type = "object"],
        $step/json:box[@type = "object"],
        $step/json:polygon[@type = "array"]
    )[1]
    return structquery:process($precedent, $ignoreRange, $useRQ)
};

declare private function structquery:process(
    $step as element(),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
)
{
    typeswitch($step)
    case element(json:item) return structquery:dispatch($step, $ignoreRange, $useRQ)
    case element(json:and) return cts:and-query(for $item in $step/json:item[@type = "object"] return structquery:process($item, $ignoreRange, $useRQ))
    case element(json:or) return cts:or-query(for $item in $step/json:item[@type = "object"] return structquery:process($item, $ignoreRange, $useRQ))
    case element(json:not) return cts:not-query(structquery:dispatch($step, $ignoreRange, $useRQ))
    case element(json:andNot) return structquery:handleAndNot($step, $ignoreRange, $useRQ)
    case element(json:near) return structquery:handleNear($step, $ignoreRange, $useRQ)
    case element(json:isNULL) return structquery:handleIsNULL($step)
    case element(json:keyExists) return structquery:handleKeyExists($step)
    case element(json:elementExists) return structquery:handleElementExists($step)
    case element(json:underElement) return structquery:handleUnderElement($step, $ignoreRange, $useRQ)
    case element(json:underKey) return structquery:handleUnderKey($step, $ignoreRange, $useRQ)
    case element(json:boolean) return structquery:handleBoolean($step)

    case element(json:key) return structquery:handleKey($step)
    case element(json:element) return structquery:handleElement($step)
    case element(json:property) return structquery:handleProperty($step)
    case element(json:place) return structquery:handlePlace($step)
    case element(json:range) return structquery:handleRange($step, $ignoreRange)
    case element(json:collection) return structquery:handleCollection($step)
    case element(json:directory) return structquery:handleDirectory($step)
    case element(json:stringQuery) return structquery:handleStringQuery($step, $ignoreRange, $useRQ)
    case element(json:namedQuery) return structquery:handleNamedQuery($step, $ignoreRange, $useRQ)
    case element(json:wordAnywhere) return structquery:handleWordAnywhere($step)
    case element(json:wordInBinary) return structquery:handleWordInBinary($step)
    case element(json:inTextDocument) return structquery:handleInTextDocument($step)
    case element(json:contentType) return structquery:handleContentType($step)

    case element(json:geo) return structquery:handleGeo($step)
    case element(json:region) return structquery:handleRegion($step)
    case element(json:point) return structquery:handleGeoPoint($step)
    case element(json:circle) return structquery:handleGeoCircle($step)
    case element(json:box) return structquery:handleGeoBox($step)
    case element(json:polygon) return structquery:handleGeoPolygon($step)
    default return ()
};

declare private function structquery:handleAndNot(
    $step as element(json:andNot),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:and-not-query?
{
    let $positive := $step/json:positive[@type = "object"]
    let $negative := $step/json:negative[@type = "object"]
    where exists($positive) and exists($negative)
    return cts:and-not-query(structquery:dispatch($positive, $ignoreRange, $useRQ), structquery:dispatch($negative, $ignoreRange, $useRQ))
};

declare private function structquery:handleNear(
    $step as element(json:near),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:near-query
{
    let $container := $step/..
    let $queries := for $item in $step/json:item return structquery:dispatch($item, $ignoreRange, $useRQ)
    let $distance := xs:double(($container/json:distance[@type = "number"], 10.0)[1]) 
    let $options :=
        if($container/json:ordered/@boolean = "true")
        then "ordered"
        else if($container/json:ordered/@boolean = "false")
        then "unordered"
        else ()
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    return cts:near-query($queries, $distance, $options, $weight)
};

declare private function structquery:handleIsNULL(
    $step as element(json:isNULL)
) as cts:element-attribute-value-query
{
    let $weight := xs:double(($step/../json:weight[@type = "number"], 1.0)[1])
    return cts:element-attribute-value-query(common:keyToQName(string($step)), xs:QName("type"), "null", (), $weight)
};

declare private function structquery:handleKeyExists(
    $step as element(json:keyExists)
) as cts:element-query?
{
    let $QNames := for $i in structquery:valueToStrings($step) return common:keyToQName($i)
    return cts:element-query($QNames, cts:and-query(()))
};

declare private function structquery:handleElementExists(
    $step as element(json:elementExists)
) as cts:element-query?
{
    let $QNames :=
        for $i in structquery:valueToStrings($step)
        return xs:QName($i)
    return cts:element-query($QNames, cts:and-query(()))
};

declare private function structquery:handleUnderElement(
    $step as element(json:underElement),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:element-query?
{
    let $container := $step/..
    let $query :=
        if($container/json:query/@type = "string")
        then string($container/json:query)
        else structquery:dispatch($container/json:query, $ignoreRange, $useRQ)
    return cts:element-query(xs:QName($step), $query)
};

declare private function structquery:handleUnderKey(
    $step as element(json:underKey),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:element-query?
{
    let $container := $step/..
    let $query :=
        if($container/json:query/@type = "string")
        then string($container/json:query)
        else structquery:dispatch($container/json:query, $ignoreRange, $useRQ)
    return cts:element-query(common:keyToQName($step), $query)
};

declare private function structquery:handleBoolean(
    $step as element(json:boolean)
) as cts:query
{
    if($step/@boolean = "true")
    then cts:and-query(())
    else cts:or-query(())
};

declare private function structquery:handleKey(
    $step as element(json:key)
) as cts:query?
{
    let $container := $step/..
    let $values := structquery:valueToStrings(($container/json:equals, $container/json:contains)[1])
    let $key := $container/json:key
    let $QName := common:keyToQName($key)
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    where exists($values)
    return
        if(exists($container/json:equals))
        then
            let $castAs := json:castAs($key, true())
            let $values :=
                if($castAs = "date")
                then for $value in $values return string(dateparser:parse($value))
                else $values
            return 
                if(exists($container/json:equals/@boolean))
                then cts:element-attribute-value-query($QName, xs:QName("boolean"), $values, $options, $weight)
                else if($castAs = "date")
                then cts:element-attribute-value-query($QName, xs:QName("normalized-date"), $values, $options, $weight)
                else cts:element-value-query($QName, $values, $options, $weight)

        else if(exists($container/json:contains))
        then cts:element-word-query($QName, $values, $options, $weight)
        else ()
};

declare private function structquery:handleElement(
    $step as element(json:element)
) as cts:query?
{
    let $container := $step/..
    let $values := structquery:valueToStrings(($container/json:equals, $container/json:contains)[1])
    let $element := $container/json:element
    let $attribute := $container/json:attribute[@type = "string"]
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    where exists($values)
    return
        if(exists($container/json:equals))
        then
            if(exists($attribute))
            then cts:element-attribute-value-query(xs:QName($element), xs:QName($attribute), $values, $options, $weight)
            else cts:element-value-query(xs:QName($element), $values, $options, $weight)
        else if(exists($container/json:contains))
        then
            if(exists($attribute))
            then cts:element-attribute-word-query(xs:QName($element), xs:QName($attribute), $values, $options, $weight)
            else cts:element-word-query(xs:QName($element), $values, $options, $weight)
        else ()
};

declare private function structquery:handleProperty(
    $step as element(json:property)
) as cts:query
{
    cts:properties-query(
        let $container := $step/..
        let $values := structquery:valueToStrings(($container/json:equals, $container/json:contains)[1])
        let $QName := xs:QName(concat("corona:", $step))
        let $options := structquery:extractOptions($container, "word")
        let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
        where exists($values)
        return
            if(exists($container/json:equals))
            then cts:element-value-query($QName, $values, $options, $weight)

            else if(exists($container/json:contains))
            then cts:element-word-query($QName, $values, $options, $weight)
            else ()
    )
};

declare private function structquery:handlePlace(
    $step as element(json:place)
) as cts:query?
{
    let $container := $step/..
    let $index := config:get(string($step))
    let $values := structquery:valueToStrings(($container/json:equals, $container/json:contains)[1])
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    where exists($values)
    return search:placeValueToQuery($index, $values, $options, $weight)
};

declare private function structquery:handleRange(
    $step as element(json:range),
    $ignoreRange as xs:string?
) as cts:query?
{
    let $container := $step/..
    let $indexName := string($step)
    let $index := config:get($indexName)
    let $options := structquery:extractOptions($container, "range")
    where if(exists($ignoreRange)) then $indexName != $ignoreRange else true() and exists($index)
    return

        if($index/@type = ("bucketedrange", "autobucketedrange") and exists($container/json:bucketLabel))
        then search:bucketLabelToQuery($index, string($container/json:bucketLabel), $options)

        else if(exists($container/json:from) and exists($container/json:to))
        then cts:and-query((
            search:rangeValueToQuery($index, string($container/json:from), "ge", $options),
            search:rangeValueToQuery($index, string($container/json:to), "le", $options)
        ))

        else
            (: • If the user has specified an operator, use that.
               • If the index name implies an operator, for example date-before:…, use the implied operator
               • Otherwise default to equality :)
            let $operator := (string($container/json:operator[@type = "string"]), string($index/operator), "eq")[1]
            let $values := 
                if($container/json:value/@type = "array")
                then $container/json:value//json:item
                else $container/json:value
            return search:rangeValueToQuery($index, $values, $operator, $options)
};

declare private function structquery:handleCollection(
    $step as element(json:collection)
) as cts:collection-query
{
    cts:collection-query(structquery:valueToStrings($step))
};

declare private function structquery:handleDirectory(
    $step as element(json:directory)
) as cts:directory-query?
{
    cts:directory-query(structquery:valueToStrings($step), if($step/../json:descendants/@boolean = "true") then "infinity" else "1")
};

declare private function structquery:handleStringQuery(
    $step as element(json:stringQuery),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
    stringquery:parse(string($step), $ignoreRange, $useRQ)
};

declare private function structquery:handleNamedQuery(
    $step as element(json:namedQuery),
    $ignoreRange as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
    search:getStoredQueryCTS(string($step), $ignoreRange, $useRQ)
};

declare private function structquery:handleWordAnywhere(
    $step as element(json:wordAnywhere)
) as cts:word-query
{
    let $container := $step/..
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    return cts:word-query(structquery:valueToStrings($step), $options, $weight)
};

declare private function structquery:handleWordInBinary(
    $step as element(json:wordInBinary)
) as cts:element-word-query
{
    let $container := $step/..
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    return cts:element-word-query(xs:QName("corona:extractedPara"), structquery:valueToStrings($step), $options, $weight)
};

declare private function structquery:handleInTextDocument(
    $step as element(json:inTextDocument)
) as cts:and-query
{
    let $container := $step/..
    let $options := structquery:extractOptions($container, "word")
    let $weight := xs:double(($container/json:weight[@type = "number"], 1.0)[1])
    return
        cts:and-query((
            cts:term-query(2328177500544466626),
            cts:word-query(structquery:valueToStrings($step), $options, $weight)
        ))
};

declare private function structquery:handleContentType(
    $step as element(json:contentType)
) as cts:query?
{
    if($step = "json")
    then cts:term-query(13332737702526692693)
    else if($step = "xml")
    then cts:and-not-query(cts:term-query(15041569596143136458), cts:term-query(13332737702526692693))
    else if($step = "text")
    then cts:term-query(2328177500544466626)
    else if($step = "binary")
    then cts:term-query(7908746777995149422)
    else ()
};

declare private function structquery:handleGeo(
    $step as element(json:geo)
) as cts:query?
{
    let $index := config:get(string($step))
    let $region := structquery:process($step/../json:region, (), true())
    let $options := structquery:extractOptions($step/.., "geo")
    let $weight := xs:double(($step/../json:weight[@type = "number"], 1.0)[1])
    return search:geoQuery($index, $region, $options, $weight)
};

declare private function structquery:handleRegion(
    $step as element()
)
{
    if($step[@type = "array"])
    then for $item in $step/json:item[@type = "object"] return structquery:process($item, (), true())
    else structquery:dispatch($step, (), true())
};

declare private function structquery:handleGeoPoint(
    $step as element()
) as cts:point?
{
    if(exists($step/json:latitude) and exists($step/json:longitude))
    then cts:point($step/json:latitude, $step/json:longitude)
    else ()
};

declare private function structquery:handleGeoCircle(
    $step as element(json:circle)
) as cts:circle?
{
    if(exists($step/json:radius) and exists($step/json:latitude) and exists($step/json:longitude))
    then cts:circle($step/json:radius, structquery:handleGeoPoint($step))
    else ()
};

declare private function structquery:handleGeoBox(
    $step as element(json:box)
) as cts:box
{
    if(exists($step/json:south) and exists($step/json:west) and exists($step/json:north) and exists($step/json:east))
    then cts:box($step/json:south, $step/json:west, $step/json:north, $step/json:east)
    else ()
};

declare private function structquery:handleGeoPolygon(
    $step as element(json:polygon)
) as cts:polygon
{
    cts:polygon(
        for $point in $step/json:item
        return structquery:handleGeoPoint($point)
    )
};


declare private function structquery:valueToStrings(
    $item as element()?
) as xs:string*
{
    if($item/@type = "array")
    then
        for $i in $item/json:item
        return structquery:valueToStrings($i)
    else if(exists($item/@boolean))
    then string($item/@boolean)
    else if($item/@type = "object")
    then ()
    else string($item)
};

declare private function structquery:extractOptions(
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
        if(exists($item/json:language[@type = "string"]))
        then concat("lang=", string($item/json:language[@type = "string"]))
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

declare private function structquery:extractWeight(
    $tree as element(json:json)
) as xs:double
{
    xs:double(($tree/json:weight[@type = "number"], 1.0)[1])
};
