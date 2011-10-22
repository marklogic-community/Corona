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

module namespace config="http://marklogic.com/corona/index-config";

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace prop="http://xqdev.com/prop" at "properties.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";

declare namespace corona="http://marklogic.com/corona";
declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function config:delete(
    $name as xs:string
) as empty-sequence()
{
    prop:delete(concat("corona-index-", $name))
};

declare function config:setJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("range/json/", $name, "/", $key, "/", $type))
};

declare function config:setXMLElementRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("range/xmlelement/", $name, "/", $element, "/", $type))
};

declare function config:setXMLAttributeRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("range/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type))
};

declare function config:setJSONBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("bucketedrange/json/", $name, "/", $key, "/", $type, "/", config:bucketElementsToString($buckets, $type, "json")))
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
    prop:set(concat("corona-index-", $name), concat("autobucketedrange/json/", $name, "/", $key, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setXMLElementBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("bucketedrange/xmlelement/", $name, "/", $element, "/", $type, "/", config:bucketElementsToString($buckets, $type, "xml")))
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
    prop:set(concat("corona-index-", $name), concat("autobucketedrange/xmlelement/", $name, "/", $element, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setXMLAttributeBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), concat("bucketedrange/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type, "/", config:bucketElementsToString($buckets, $type, "xml")))
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
    prop:set(concat("corona-index-", $name), concat("autobucketedrange/xmlattribute/", $name, "/", $element, "/", $attribute, "/", $type, "/", $bucketInterval, "/", $startingAt, "/", $stoppingAt, "/", xdmp:url-encode($firstFormat), "/", xdmp:url-encode($format), "/", xdmp:url-encode($lastFormat)))
};

declare function config:setPlace(
    $placeName as xs:string?,
    $config as element(index)
) as empty-sequence()
{
    let $placeName :=
        if(exists($placeName))
        then concat("corona-index-", $placeName)
        else "corona-index--anonymous-place"
    return prop:set($placeName, $config, true())
};

declare function config:getPlace(
    $placeName as xs:string?
) as element(index)?
{
    let $name :=
        if(exists($placeName))
        then concat("corona-index-", $placeName)
        else "corona-index--anonymous-place"
    let $config := prop:get($name)
    return
        if(empty($placeName) and empty($config))
        then <index type="place" anonymous="true"/>
        else $config
};

declare function config:get(
    $name as xs:string
) as element(index)?
{
    let $property := prop:get(concat("corona-index-", $name))
    let $isPsudo :=
        if(empty($property) and (ends-with($name, "-above") or ends-with($name, "-below") or ends-with($name, "-before") or ends-with($name, "-after")))
        then true()
        else false()
    let $property :=
        if($isPsudo)
        then prop:get(concat("corona-index-", replace($name, "-above$|-below$|-before$|-after$", "")))
        else $property
    let $operator :=
        if(exists($property) and $isPsudo)
        then
            if(ends-with($name, "-above") or ends-with($name, "-after"))
            then "ge"
            else if(ends-with($name, "-before") or ends-with($name, "-below"))
            then "le"
            else ()
        else ()
    let $bits :=
        if($property instance of xs:string)
        then tokenize($property, "/")
        else ()
    where exists($property)
    return
        if($property instance of element() and $property/@type = "place")
        then $property
        else if($bits[1] = "range")
        then <index type="range" name="{ $bits[3] }">
            <structure>{ $bits[2] }</structure>
            {
                if($bits[2] = "json")
                then (
                    <key>{ $bits[4] }</key>,
                    <type>{ $bits[5] }</type>
                )
                else if($bits[2] = "xmlelement")
                then (
                    <element>{ $bits[4] }</element>,
                    <type>{ $bits[5] }</type>
                )
                else if($bits[2] = "xmlattribute")
                then (
                    <element>{ $bits[4] }</element>,
                    <attribute>{ $bits[5] }</attribute>,
                    <type>{ $bits[6] }</type>
                )
                else ()
            }
            {
                if(exists($operator))
                then <operator>{ $operator }</operator>
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
        else ()
};

declare function config:rangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and starts-with($value, "range/")
    return substring-after($key, "corona-index-")
};

declare function config:bucketedRangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and (starts-with($value, "bucketedrange/") or starts-with($value, "autobucketedrange/"))
    return substring-after($key, "corona-index-")
};

declare function config:placeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where $value instance of element() and starts-with($key, "corona-index-") and $value/@type = "place" and exists($value/@name)
    return string($value/@name)
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
            then error(xs:QName("corona:INVALID-BUCKETS"), "The first and last bucket elements must be labels")
            else ()
        for $bucket at $pos in $buckets
        let $check :=
            if($pos mod 2 = 0 and local-name($bucket) != "boundary")
            then error(xs:QName("corona:INVALID-BUCKETS"), "Even bucket elements need to be boundary elements")
            else if($pos mod 2 != 0 and local-name($bucket) != "label")
            then error(xs:QName("corona:INVALID-BUCKETS"), "Odd bucket elements ned to be label elements")
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
            then error(xs:QName("corona:INVALID-BUCKETS"), concat("Bucket value '", $boundaryValue, "' is not of the correct datatype"))
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
