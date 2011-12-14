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

module namespace sqt="http://marklogic.com/corona/structured-query-translator";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare namespace corona="http://marklogic.com/corona";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function sqt:translate(
    $query as element()
) as element(json:json)
{
    json:document(sqt:process($query))
};

declare private function sqt:process(
    $step as element()
) as item()*
{
    typeswitch($step)
    case element(constraint) return sqt:createObjectOutputKeyProcessValue($step)
    case element(and) return json:object(("and", sqt:outputChildrenAsArray($step)))
    case element(or) return json:object(("or", sqt:outputChildrenAsArray($step)))
    case element(near) return json:array(for $item in $step/constraint return sqt:createObjectOutputKeyProcessValue($item))
    case element(not) return json:object(("not", sqt:process(($step/*)[1])))
    case element(andNot) return sqt:handleObjectValue($step)
    case element(query) return
        if(exists($step/*))
        then sqt:process(($step/*)[1])
        else sqt:handleValue($step)

    case element(positive) return sqt:process(($step/*)[1])
    case element(negative) return sqt:process(($step/*)[1])

    case element(boolean) return sqt:handleSimpleKeyValue($step, "boolean")
    case element(isNULL) return sqt:handleSimpleKeyValue($step, ())
    case element(keyExists) return sqt:handleSimpleKeyValue($step, ())
    case element(elementExists) return sqt:handleSimpleKeyValue($step, ())
    case element(collection) return sqt:handleSimpleKeyValue($step, ())
    case element(namedQuery) return sqt:handleSimpleKeyValue($step, ())

    case element(equals) return sqt:handleMixedValue($step)
    case element(contains) return sqt:handleMixedValue($step)
    case element(value) return sqt:handleMixedValue($step)
    case element(wordAnywhere) return sqt:handleMixedValue($step)
    case element(wordInBinary) return sqt:handleMixedValue($step)
    case element(inTextDocument) return sqt:handleMixedValue($step)

    case element(weight) return xs:decimal($step)
    case element(distance) return xs:decimal($step)
    case element(minimumOccurances) return xs:integer($step)
    case element(maximumOccurances) return xs:integer($step)
    case element(caseSensitive) return xs:boolean($step)
    case element(diacriticSensitive) return xs:boolean($step)
    case element(punctuationSensitve) return xs:boolean($step)
    case element(whitespaceSensitive) return xs:boolean($step)
    case element(stemmed) return xs:boolean($step)
    case element(wildcarded) return xs:boolean($step)
    case element(descendants) return xs:boolean($step)
    case element(ordered) return xs:boolean($step)

    (: Geo :)
    case element(geo) return sqt:handleValue($step)
    case element(region) return sqt:handleValue($step)
    case element(point) return sqt:handleValue($step)
    case element(circle) return sqt:handleValue($step)
    case element(box) return sqt:handleValue($step)
    case element(polygon) return sqt:outputChildrenAsArray($step)
    case element(latitude) return xs:decimal($step)
    case element(longitude) return xs:decimal($step)
    case element(radius) return xs:decimal($step)
    case element(north) return xs:decimal($step)
    case element(south) return xs:decimal($step)
    case element(east) return xs:decimal($step)
    case element(west) return xs:decimal($step)

    default return string($step)
};

declare private function sqt:createObjectOutputKeyProcessValue(
    $step as element()
) as element(json:item)
{
    json:object(
        for $item in $step/*
        return (local-name($item), sqt:process($item))
    )
};

declare private function sqt:outputChildrenAsArray(
    $step as element()
) as element(json:item)
{
    json:array(for $item in $step/* return sqt:process($item))
};

declare private function sqt:handleObjectValue(
    $step as element()
) as element(json:item)
{
    json:object((local-name($step), sqt:createObjectOutputKeyProcessValue($step)))
};

declare private function sqt:handleMixedValue(
    $step as element()
)
{
    if(exists($step/*))
    then json:array(for $i in $step/value return sqt:handleValue($i))
    else sqt:handleValue($step)
};

declare private function sqt:handleSimpleKeyValue(
    $step as element(),
    $castAs as xs:string?
) as element()
{
    if($castAs = "boolean")
    then json:object((local-name($step), xs:boolean($step)))
    else if($castAs = "number")
    then json:object((local-name($step), xs:decimal($step)))
    else if($castAs = "string")
    then json:object((local-name($step), xs:string($step)))
    else json:object((local-name($step), sqt:handleMixedValue($step)))
};

declare private function sqt:handleValue(
    $value as element()
)
{
    if(exists($value/*))
    then sqt:createObjectOutputKeyProcessValue($value)
    else if(empty($value/@type) or $value/@type = "string")
    then string($value)
    else if($value/@type = "boolean")
    then xs:boolean($value)
    else if($value/@type = "number")
    then xs:decimal($value)
    else string($value)
};

