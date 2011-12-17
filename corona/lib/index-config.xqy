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

declare function config:addNamedQueryPrefix(
    $prefix as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $prefix), <index type="namedQueryPrefix" name="{ $prefix }"/>)
};

declare function config:prefixes(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and $value/@type = "namedQueryPrefix"
    return substring-after($key, "corona-index-")
};

declare function config:setJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $collation as xs:string?
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="range" name="{ $name }">
        <structure>json</structure>
        <key>{ $key }</key>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
    </index>)
};

declare function config:setXMLElementRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $collation as xs:string?
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="range" name="{ $name }">
        <structure>xmlelement</structure>
        <element>{ $element }</element>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
    </index>)
};

declare function config:setXMLAttributeRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $collation as xs:string?
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="range" name="{ $name }">
        <structure>xmlattribute</structure>
        <element>{ $element }</element>
        <attribute>{ $attribute }</attribute>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
    </index>)
};

declare function config:setJSONBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="bucketedrange" name="{ $name }">
        <structure>json</structure>
        <key>{ $key }</key>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        { config:generateBucketStructure($buckets, $type, "json") }
    </index>)
};

declare function config:setJSONAutoBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="autobucketedrange" name="{ $name }">
        <structure>json</structure>
        <key>{ $key }</key>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        <bucketInterval>{ $bucketInterval }</bucketInterval>
        <startingAt>{ $startingAt }</startingAt>
        { if(exists($stoppingAt)) then <stoppingAt>{ $stoppingAt }</stoppingAt> else () }
        <firstFormat>{ $firstFormat }</firstFormat>
        <format>{ $format }</format>
        <lastFormat>{ $lastFormat }</lastFormat>
    </index>)
};

declare function config:setXMLElementBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="bucketedrange" name="{ $name }">
        <structure>xmlelement</structure>
        <element>{ $element }</element>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        { config:generateBucketStructure($buckets, $type, "xml") }
    </index>)
};

declare function config:setXMLElementAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="autobucketedrange" name="{ $name }">
        <structure>xmlelement</structure>
        <element>{ $element }</element>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        <bucketInterval>{ $bucketInterval }</bucketInterval>
        <startingAt>{ $startingAt }</startingAt>
        { if(exists($stoppingAt)) then <stoppingAt>{ $stoppingAt }</stoppingAt> else () }
        <firstFormat>{ $firstFormat }</firstFormat>
        <format>{ $format }</format>
        <lastFormat>{ $lastFormat }</lastFormat>
    </index>)
};

declare function config:setXMLAttributeBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $buckets as element()+
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="bucketedrange" name="{ $name }">
        <structure>xmlattribute</structure>
        <element>{ $element }</element>
        <attribute>{ $attribute }</attribute>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        { config:generateBucketStructure($buckets, $type, "xml") }
    </index>)
};

declare function config:setXMLAttributeAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $collation as xs:string?,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="autobucketedrange" name="{ $name }">
        <structure>xmlattribute</structure>
        <element>{ $element }</element>
        <attribute>{ $attribute }</attribute>
        <type>{ $type }</type>
        { if($type = "string") then <collation>{ $collation }</collation> else () }
        <bucketInterval>{ $bucketInterval }</bucketInterval>
        <startingAt>{ $startingAt }</startingAt>
        { if(exists($stoppingAt)) then <stoppingAt>{ $stoppingAt }</stoppingAt> else () }
        <firstFormat>{ $firstFormat }</firstFormat>
        <format>{ $format }</format>
        <lastFormat>{ $lastFormat }</lastFormat>
    </index>)
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


declare function config:setGeoWithAttributes(
    $name as xs:string,
    $parentElement as xs:string,
    $latAttribute as xs:string,
    $longAttribute as xs:string,
    $coordinateSystem as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>elementWithAttributes</structure>
        <parentElement>{ $parentElement }</parentElement>
        <latAttribute>{ $latAttribute }</latAttribute>
        <longAttribute>{ $longAttribute }</longAttribute>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
    </index>)
};

declare function config:setGeoWithElementChildren(
    $name as xs:string,
    $parentElement as xs:string,
    $latElement as xs:string,
    $longElement as xs:string,
    $coordinateSystem as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>elementWithChildren</structure>
        <parentElement>{ $parentElement }</parentElement>
        <latElement>{ $latElement }</latElement>
        <longElement>{ $longElement }</longElement>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
    </index>)
};

declare function config:setGeoWithKeyChildren(
    $name as xs:string,
    $parentKey as xs:string,
    $latKey as xs:string,
    $longKey as xs:string,
    $coordinateSystem as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>keyWithChildren</structure>
        <parentKey>{ $parentKey }</parentKey>
        <latKey>{ $latKey }</latKey>
        <longKey>{ $longKey }</longKey>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
    </index>)
};

declare function config:setGeoWithElementChild(
    $name as xs:string,
    $parentElement as xs:string,
    $element as xs:string,
    $coordinateSystem as xs:string,
    $comesFirst as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>elementWithChild</structure>
        <parentElement>{ $parentElement }</parentElement>
        <element>{ $element }</element>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
        <comesFirst>{ $comesFirst }</comesFirst>
    </index>)
};

declare function config:setGeoWithKeyChild(
    $name as xs:string,
    $parentKey as xs:string,
    $key as xs:string,
    $coordinateSystem as xs:string,
    $comesFirst as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>keyWithChild</structure>
        <parentKey>{ $parentKey }</parentKey>
        <key>{ $key }</key>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
        <comesFirst>{ $comesFirst }</comesFirst>
    </index>)
};

declare function config:setGeoWithElement(
    $name as xs:string,
    $element as xs:string,
    $coordinateSystem as xs:string,
    $comesFirst as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>element</structure>
        <element>{ $element }</element>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
        <comesFirst>{ $comesFirst }</comesFirst>
    </index>)
};

declare function config:setGeoWithKey(
    $name as xs:string,
    $key as xs:string,
    $coordinateSystem as xs:string,
    $comesFirst as xs:string
) as empty-sequence()
{
    prop:set(concat("corona-index-", $name), <index type="geo" name="{ $name }">
        <structure>key</structure>
        <key>{ $key }</key>
        <coordinateSystem>{ $coordinateSystem }</coordinateSystem>
        <comesFirst>{ $comesFirst }</comesFirst>
    </index>)
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
    where exists($property)
    return
        if($property/@type = "range" and $isPsudo)
        then <index>
            { $property/@* }
            { $property/* }
            <operator>{ $operator }</operator>
        </index>
        else $property
};

declare function config:rangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and $value/@type = "range"
    return substring-after($key, "corona-index-")
};

declare function config:bucketedRangeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and $value/@type = ("bucketedrange", "autobucketedrange")
    return substring-after($key, "corona-index-")
};

declare function config:placeNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and $value/@type = "place" and exists($value/@name)
    return string($value/@name)
};

declare function config:geoNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "corona-index-") and $value/@type = "geo" and exists($value/@name)
    return string($value/@name)
};


(: Private functions :)

declare private function config:generateBucketStructure(
    $buckets as element()+,
    $type as xs:string,
    $format as xs:string
) as element(buckets)
{
    <buckets>{
        let $xsType :=
            if($format = "json")
            then
                if($type = "number")
                then "decimal"
                else if($type = "date")
                then "dateTime"
                else "string"
            else $type
        let $test :=
            if(local-name($buckets[1]) != "label" or local-name($buckets[last()]) != "label")
            then error(xs:QName("corona:INVALID-BUCKETS"), "The first and last bucket elements must be labels")
            else ()
        for $bucket at $pos in $buckets
        let $test :=
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
        let $test :=
            if(local-name($bucket) = "boundary" and not(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, $boundaryValue)))
            then error(xs:QName("corona:INVALID-BUCKETS"), concat("Bucket value '", $boundaryValue, "' is not of the correct datatype"))
            else ()
        return $bucket
    }</buckets>
};
