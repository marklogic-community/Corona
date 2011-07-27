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
                    <attribute>{ $bits[4] }</attribute>,
                    <type>{ $bits[6] }</type>,
                    <operator>{ $bits[7] }</operator>
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

declare function config:mapNames(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and starts-with($value, "map/")
    return substring-after($key, "index-")
};
