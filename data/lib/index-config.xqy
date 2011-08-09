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

module namespace config="http://marklogic.com/mljson/index-config";

import module namespace prop="http://xqdev.com/prop" at "properties.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function config:delete(
    $name as xs:string
) as empty-sequence()
{
    prop:delete(concat("index-", $name))
};

declare function config:setField(
    $name as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("field/", $name))
};

declare function config:setJSONMap(
    $name as xs:string,
    $key as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("map/json/", $name, "/", $key, "/", $mode))
};

declare function config:setXMLMap(
    $name as xs:string,
    $element as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("map/xmlelement/", $name, "/", $element, "/", $mode))
};

declare function config:setJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $operator as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("range/json/", $name, "/", $key, "/", $type, "/", $operator))
};

declare function config:setXMLElementRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $operator as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("range/xmlelement/", $name, "/", $element, "/", $type, "/", $operator))
};

declare function config:setXMLAttributeRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $operator as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("range/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type, "/", $operator))
};

declare function config:setJSONBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("bucketedrange/json/", $name, "/", $key, "/", $type, "/", config:bucketElementsToString($buckets, $type, "json")))
};

declare function config:setJSONAutoBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("autobucketedrange/json/", $name, "/", $key, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setXMLElementBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("bucketedrange/xmlelement/", $name, "/", $element, "/", $type, "/", config:bucketElementsToString($buckets, $type, "xml")))
};

declare function config:setXMLElementAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("autobucketedrange/xmlelement/", $name, "/", $element, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setXMLAttributeBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("bucketedrange/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type, "/", config:bucketElementsToString($buckets, $type, "xml")))
};

declare function config:setXMLAttributeAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("index-", $name), concat("autobucketedrange/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setContentItems(
    $items as element(item)*
) as empty-sequence()
{
    prop:delete("mljson-content-items"),
    let $elements := string-join(
        for $item in $items[@type = "element"]
        return concat(string($item), "=", $item/@weight)
    , "|")
    let $keys := string-join(
        for $item in $items[@type = "key"]
        return concat(string($item), "=", $item/@weight)
    , "|")
    let $fields := string-join(
        for $item in $items[@type = "field"]
        return concat(string($item), "=", $item/@weight)
    , "|")
    return prop:set("mljson-content-items", concat($elements, "/", $keys, "/", $fields))
};

declare function config:getContentItems(
) as element(item)*
{
    let $bits := tokenize(prop:get("mljson-content-items"), "/")
    let $elements :=
        for $item in tokenize($bits[1], "\|")
        let $elementBits := tokenize($item, "=")
        return <item type="element" weight="{ $elementBits[2] }">{ $elementBits[1] }</item>
    let $keys :=
        for $item in tokenize($bits[2], "\|")
        let $keyBits := tokenize($item, "=")
        return <item type="key" weight="{ $keyBits[2] }">{ $keyBits[1] }</item>
    let $fields :=
        for $item in tokenize($bits[3], "\|")
        let $fieldBits := tokenize($item, "=")
        return <item type="field" weight="{ $fieldBits[2] }">{ $fieldBits[1] }</item>
    return ($elements, $keys, $fields)
};

declare function config:get(
    $name as xs:string
) as element(index)?
{
    let $property := prop:get(concat("index-", $name))
    let $bits := tokenize($property, "/")
    where exists($property)
    return
        if($bits[1] = "range")
        then <index type="range" name="{ $bits[3] }">
            <structure>{ $bits[2] }</structure>
            {
                if($bits[2] = "json")
                then (
                    <key>{ $bits[4] }</key>,
                    <type>{ $bits[5] }</type>,
                    <operator>{ $bits[6] }</operator>
                )
                else if($bits[2] = "xmlelement")
                then (
                    <element>{ $bits[4] }</element>,
                    <type>{ $bits[5] }</type>,
                    <operator>{ $bits[6] }</operator>
                )
                else if($bits[2] = "xmlattribute")
                then (
                    <element>{ $bits[4] }</element>,
                    <attribute>{ $bits[5] }</attribute>,
                    <type>{ $bits[6] }</type>,
                    <operator>{ $bits[7] }</operator>
                )
                else ()
            }
        </index>
        else if($bits[1] = "bucketedrange")
        then <index type="bucketedrange" name="{ $bits[3] }">
            <structure>{ $bits[2] }</structure>
            {
                if($bits[2] = "json")
                then (
                    <key>{ $bits[4] }</key>,
                    <type>{ $bits[5] }</type>,
                    <buckets>{ config:bucketStringToElements($bits[6]) }</buckets>
                )
                else if($bits[2] = "xmlelement")
                then (
                    <element>{ $bits[4] }</element>,
                    <type>{ $bits[5] }</type>,
                    <buckets>{ config:bucketStringToElements($bits[6]) }</buckets>
                )
                else if($bits[2] = "xmlattribute")
                then (
                    <element>{ $bits[4] }</element>,
                    <attribute>{ $bits[5] }</attribute>,
                    <type>{ $bits[6] }</type>,
                    <buckets>{ config:bucketStringToElements($bits[7]) }</buckets>
                )
                else ()
            }
        </index>
        else if($bits[1] = "autobucketedrange")
        then <index type="autobucketedrange" name="{ $bits[3] }">
            <structure>{ $bits[2] }</structure>
            {
                if($bits[2] = "json")
                then (
                    <key>{ $bits[4] }</key>,
                    <type>{ $bits[5] }</type>,
                    <bucketInterval>{ $bits[6] }</bucketInterval>,
                    <startingAt>{ $bits[7] }</startingAt>,
                    if(string-length($bits[8])) then <stoppingAt>{ $bits[8] }</stoppingAt> else (),
                    <firstFormat>{ xdmp:url-decode($bits[9]) }</firstFormat>,
                    <format>{ xdmp:url-decode($bits[10]) }</format>,
                    <lastFormat>{ xdmp:url-decode($bits[11]) }</lastFormat>
                )
                else if($bits[2] = "xmlelement")
                then (
                    <element>{ $bits[4] }</element>,
                    <type>{ $bits[5] }</type>,
                    <bucketInterval>{ $bits[6] }</bucketInterval>,
                    <startingAt>{ $bits[7] }</startingAt>,
                    if(string-length($bits[8])) then <stoppingAt>{ $bits[8] }</stoppingAt> else (),
                    <firstFormat>{ xdmp:url-decode($bits[9]) }</firstFormat>,
                    <format>{ xdmp:url-decode($bits[10]) }</format>,
                    <lastFormat>{ xdmp:url-decode($bits[11]) }</lastFormat>
                )
                else if($bits[2] = "xmlattribute")
                then (
                    <element>{ $bits[4] }</element>,
                    <attribute>{ $bits[5] }</attribute>,
                    <type>{ $bits[6] }</type>,
                    <bucketInterval>{ $bits[7] }</bucketInterval>,
                    <startingAt>{ $bits[8] }</startingAt>,
                    if(string-length($bits[9])) then <stoppingAt>{ $bits[9] }</stoppingAt> else (),
                    <firstFormat>{ xdmp:url-decode($bits[10]) }</firstFormat>,
                    <format>{ xdmp:url-decode($bits[11]) }</format>,
                    <lastFormat>{ xdmp:url-decode($bits[12]) }</lastFormat>
                )
                else ()
            }
        </index>
        else if($bits[1] = "map")
        then <index type="map" name="{ $bits[3] }">
            <structure>{ $bits[2] }</structure>
            {
                if($bits[2] = "json")
                then (
                    <key>{ $bits[4] }</key>,
                    <mode>{ $bits[5] }</mode>
                )
                else if($bits[2] = "xmlelement")
                then (
                    <element>{ $bits[4] }</element>,
                    <mode>{ $bits[5] }</mode>
                )
                else ()
            }
        </index>
        else if($bits[1] = "field")
        then <index type="field" name="{ $bits[2] }"><name>{ $bits[2] }</name></index>
        else ()
};

declare function config:rangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and starts-with($value, "range/")
    return substring-after($key, "index-")
};

declare function config:bucketedRangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and (starts-with($value, "bucketedrange/") or starts-with($value, "autobucketedrange/"))
    return substring-after($key, "index-")
};

declare function config:mapNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and starts-with($value, "map/")
    return substring-after($key, "index-")
};



declare private function config:bucketElementsToString(
    $buckets as element()+,
    $type as xs:string,
    $format as xs:string
) as xs:string
{
    string-join(

        let $xsType :=
            if($format = "json")
            then
                if($type = "number")
                then "decimal"
                else if($type = "date")
                then "dateTime"
                else "string"
            else $type
        let $check :=
            if(local-name($buckets[1]) != "label" or local-name($buckets[last()]) != "label")
            then error(xs:QName("config:INVALID-BUCKETS"), "The first and last bucket elements must be labels")
            else ()
        for $bucket at $pos in $buckets
        let $check :=
            if($pos mod 2 = 0 and local-name($bucket) != "boundary")
            then error(xs:QName("config:INVALID-BUCKETS"), "Even bucket elements need to be boundary elements")
            else if($pos mod 2 != 0 and local-name($bucket) != "label")
            then error(xs:QName("config:INVALID-BUCKETS"), "Odd bucket elements ned to be label elements")
            else ()
        let $boundaryValue :=
            if(local-name($bucket) = "boundary")
            then
                if($format = "json" and $type = "date")
                then string(dateparser:parse(string($bucket)))
                else string($bucket)
            else ()
        let $check :=
            if(local-name($bucket) = "boundary" and not(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, $boundaryValue)))
            then error(xs:QName("config:INVALID-BUCKETS"), concat("Bucket value '", $boundaryValue, "' is not of the correct datatype"))
            else ()
        return xdmp:url-encode(string($bucket))
    , "|")
};

declare private function config:bucketStringToElements(
    $string as xs:string
) as element()+
{
    for $bit at $pos in tokenize($string, "\|")
    let $bit := xdmp:url-decode($bit)
    return
        if($pos mod 2)
        then <label>{ $bit }</label>
        else <boundary>{ $bit }</boundary>
};
