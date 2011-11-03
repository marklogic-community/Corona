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

module namespace manage="http://marklogic.com/corona/manage";

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace config="http://marklogic.com/corona/index-config" at "index-config.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "constants.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace corona="http://marklogic.com/corona";
declare namespace db="http://marklogic.com/xdmp/database";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: Ranges :)
declare function manage:createJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateJSONType($type)

    let $key := json:escapeNCName($key)
    return (
        manage:createJSONRangeIndex($name, $key, $type, $config),
        config:setJSONRange($name, $key, $type)
    )
};

declare function manage:createXMLElementRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateXMLType($type)

    return (
        manage:createXMLElementRangeIndex($name, $element, $type, $config),
        config:setXMLElementRange($name, $element, $type)
    )
};

declare function manage:createXMLAttributeRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateAttributeName($attribute)
    let $test := manage:validateXMLType($type)

    return (
        manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config),
        config:setXMLAttributeRange($name, $element, $attribute, $type)
    )
};

declare function manage:deleteRange(
    $name as xs:string,
    $config as element()
) as empty-sequence()
{
    let $database := xdmp:database()
    let $index := config:get($name)
    let $existing := manage:getRangeDefinition($index, $config)
    let $numUsing := if(exists($existing)) then manage:rangeDefinitionUsedBy($existing) else 0
    where $index/@type = "range"
    return (
        if($numUsing = 1)
        then (
            if(local-name($existing) = "range-element-index")
            then admin:save-configuration(admin:database-delete-range-element-index($config, $database, $existing))
            else admin:save-configuration(admin:database-delete-range-element-attribute-index($config, $database, $existing))
        )
        else ()
        ,
        config:delete($name)
    )
};

declare function manage:getRange(
    $name as xs:string
) as element(json:item)?
{
    let $index := config:get($name)
    where $index/@type = "range"
    return
        if($index/structure = "json")
        then
            json:object((
                "name", $name,
                "key", json:unescapeNCName($index/key),
                "type", string($index/type)
            ))
        else if($index/structure = "xmlelement")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "type", string($index/type)
            ))
        else if($index/structure = "xmlattribute")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "attribute", string($index/attribute),
                "type", string($index/type)
            ))
        else ()
};

declare function manage:getAllRanges(
) as element(json:item)*
{
    for $rangeName in config:rangeNames()
    return manage:getRange($rangeName)
};


(: Bucketed ranges :)
declare function manage:createJSONBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $buckets as element()+,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateJSONType($type)
    let $test := manage:validateBuckets($buckets, manage:jsonTypeToSchemaType($type))

    let $key := json:escapeNCName($key)
    return (
        manage:createJSONRangeIndex($name, $key, $type, $config),
        config:setJSONBucketedRange($name, $key, $type, $buckets)
    )
};

declare function manage:createJSONAutoBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateJSONType($type)
    let $test := manage:validateBucketInterval($bucketInterval)
    let $test := manage:validateStartAndStop($startingAt)
    let $test := manage:validateStartAndStop($stoppingAt)

    let $key := json:escapeNCName($key)
    return (
        manage:createJSONRangeIndex($name, $key, $type, $config),
        config:setJSONAutoBucketedRange($name, $key, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat)
    )
};

declare function manage:createXMLElementBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $buckets as element()+,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateBuckets($buckets, $type)

    return (
        manage:createXMLElementRangeIndex($name, $element, $type, $config),
        config:setXMLElementBucketedRange($name, $element, $type, $buckets)
    )
};

declare function manage:createXMLElementAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateBucketInterval($bucketInterval)
    let $test := manage:validateStartAndStop($startingAt)
    let $test := manage:validateStartAndStop($stoppingAt)

    return (
        manage:createXMLElementRangeIndex($name, $element, $type, $config),
        config:setXMLElementAutoBucketedRange($name, $element, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat)
    )
};

declare function manage:createXMLAttributeBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $buckets as element()+,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateAttributeName($attribute)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateBuckets($buckets, $type)

    return (
        manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config),
        config:setXMLAttributeBucketedRange($name, $element, $attribute, $type, $buckets)
    )
};

declare function manage:createXMLAttributeAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $bucketInterval as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $firstFormat as xs:string,
    $format as xs:string,
    $lastFormat as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateAttributeName($attribute)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateBucketInterval($bucketInterval)
    let $test := manage:validateStartAndStop($startingAt)
    let $test := manage:validateStartAndStop($stoppingAt)

    return (
        manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config),
        config:setXMLAttributeAutoBucketedRange($name, $element, $attribute, $type, $bucketInterval, $startingAt, $stoppingAt, $firstFormat, $format, $lastFormat)
    )
};

declare function manage:deleteBucketedRange(
    $name as xs:string,
    $config as element()
) as empty-sequence()
{
    let $database := xdmp:database()
    let $index := config:get($name)
    let $existing := manage:getRangeDefinition($index, $config)
    let $numUsing := if(exists($existing)) then manage:rangeDefinitionUsedBy($existing) else 0
    where $index/@type = ("bucketedrange", "autobucketedrange")
    return (
        if($numUsing = 1)
        then (
            if(local-name($existing) = "range-element-index")
            then admin:save-configuration(admin:database-delete-range-element-index($config, $database, $existing))
            else admin:save-configuration(admin:database-delete-range-element-attribute-index($config, $database, $existing))
        )
        else ()
        ,
        config:delete($name)
    )
};

declare function manage:getBucketedRange(
    $name as xs:string
) as element(json:item)?
{
    let $index := config:get($name)
    let $common := (
        "type", string($index/type),
        if(exists($index/buckets))
        then ("buckets", json:array(
                for $bucket in $index/buckets/*
                return
                    if(local-name($bucket) = "boundary" and $index/@type = "number" and string($bucket) castable as xs:decimal)
                    then xs:decimal(string($bucket))
                    else string($bucket)
            )
        )
        else (),
        if(exists($index/bucketInterval))
        then ("bucketInterval", string($index/bucketInterval))
        else (),
        if(exists($index/startingAt))
        then ("startingAt", string($index/startingAt))
        else (),
        if(string-length($index/stoppingAt))
        then ("stoppingAt", string($index/stoppingAt))
        else (),
        if(exists($index/firstFormat))
        then ("firstFormat", string($index/firstFormat))
        else (),
        if(exists($index/format))
        then ("format", string($index/format))
        else (),
        if(exists($index/lastFormat))
        then ("lastFormat", string($index/lastFormat))
        else ()
    )
    where $index/@type = ("bucketedrange", "autobucketedrange")
    return
        if($index/structure = "json")
        then
            json:object((
                "name", $name,
                "key", json:unescapeNCName($index/key),
                $common
            ))
        else if($index/structure = "xmlelement")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                $common
            ))
        else if($index/structure = "xmlattribute")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "attribute", string($index/attribute),
                $common
            ))
        else ()
};

declare function manage:getAllBucketedRanges(
) as element(json:item)*
{
    for $name in config:bucketedRangeNames()
    return manage:getBucketedRange($name)
};


(: Namespaces :)
declare function manage:setNamespaceURI(
    $prefix as xs:string,
    $uri as xs:string
) as empty-sequence()
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    let $existing := admin:group-get-namespaces($config, $group)[*:prefix = $prefix]
    let $config :=
        if(exists($existing))
        then admin:group-delete-namespace($config, $group, $existing)
        else $config

    let $namespace := admin:group-namespace($prefix, $uri)
    return admin:save-configuration(admin:group-add-namespace($config, $group, $namespace))
};

declare function manage:deleteNamespace(
    $prefix as xs:string
) as empty-sequence()
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    let $namespace := admin:group-get-namespaces($config, $group)[*:prefix = $prefix]
    where exists($namespace)
    return admin:save-configuration(admin:group-delete-namespace($config, $group, $namespace))
};

declare function manage:getNamespaceURI(
    $prefix as xs:string
) as element(json:item)*
{
    let $uri :=
        try {
            namespace-uri(element { concat($prefix, ":foo") } { () })
        }
        catch($e) {
            ()
        }
    where exists($uri) and not(starts-with($prefix, "index-"))
    return
        json:object((
            "prefix", $prefix,
            "uri", $uri
        ))
};

declare function manage:getAllNamespaces(
) as element(json:item)*
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    for $namespace in admin:group-get-namespaces($config, $group)
    where not(starts-with(string($namespace/*:namespace-uri), "http://xqdev.com/prop/"))
    return json:object((
        "prefix", string($namespace/*:prefix),
        "uri", string($namespace/*:namespace-uri)
    ))
};

(: Places :)
declare function manage:createPlace(
    $placeName as xs:string,
    $mode as xs:string,
    $options as xs:string*
) as empty-sequence()
{
    let $test := manage:validateIndexName($placeName)
    let $test := manage:validateMode($mode)
    let $test := if($mode = "equals") then manage:checkForFieldValueCapability() else ()
    let $config := <index type="place" name="{ $placeName }" mode="{ $mode }">
        <options>{
        }</options>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return config:setPlace($placeName, $config)
};

declare function manage:deletePlace(
    $placeName as xs:string
) as empty-sequence()
{
    config:delete($placeName),
    (: Using a fake stub of an index here just to wipe out the database field if one exists :)
    manage:createFieldForPlace(<index type="place" name="{ $placeName }"><field name="{ manage:generateFieldName($placeName) }"/></index>)
};

declare function manage:addKeyToPlace(
    $placeName as xs:string?,
    $key as xs:string,
    $type as xs:string,
    $weight as xs:decimal
) as empty-sequence()
{
    let $test := manage:validatePlaceType($type)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $needsField := exists($existingConfig/query/field) or $type = "exclude"
    let $newKey := <key key="{ $key }" weight="{ $weight }" type="{ $type }"/>
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{
            if($needsField)
            then (
                <field name="{ manage:generateFieldName($placeName) }">{(
                    $existingConfig/query/field/*,
                    $existingConfig/query/(element, key),
                    $newKey
                )}</field>,
                $existingConfig/query/(attribute, place)
            )
            else ($existingConfig/query/* except $existingConfig/query/field, $newKey)
        }</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:addElementToPlace(
    $placeName as xs:string?,
    $elementName as xs:string,
    $type as xs:string,
    $weight as xs:decimal
) as empty-sequence()
{
    let $test := manage:validateElementName($elementName)
    let $test := manage:validatePlaceType($type)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $needsField := exists($existingConfig/query/field) or $type = "exclude"
    let $newElement := <element element="{ $elementName }" weight="{ $weight }" type="{ $type }"/>
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{
            if($needsField)
            then (
                <field name="{ manage:generateFieldName($placeName) }">{(
                    $existingConfig/query/field/*,
                    $existingConfig/query/(element, key),
                    $newElement
                )}</field>,
                $existingConfig/query/(attribute, place)
            )
            else ($existingConfig/query/* except $existingConfig/query/field, $newElement)
        }</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:addAttributeToPlace(
    $placeName as xs:string?,
    $elementName as xs:string,
    $attributeName as xs:string,
    $weight as xs:decimal
) as empty-sequence()
{
    let $test := manage:validateElementName($elementName)
    let $test := manage:validateAttributeName($attributeName)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            $existingConfig/query/*,
            <attribute element="{ $elementName }" attribute="{ $attributeName }" weight="{ $weight }"/>
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:addPlaceToPlace(
    $placeName as xs:string?,
    $subPlaceName as xs:string
) as empty-sequence()
{
    let $test := manage:checkForPlaceLoops($subPlaceName, $placeName)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            $existingConfig/query/*,
            <place name="{ $subPlaceName }"/>
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:removeKeyFromPlace(
    $placeName as xs:string?,
    $key as xs:string,
    $type as xs:string
) as empty-sequence()
{
    let $test := manage:validatePlaceType($type)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            if(exists($existingConfig/query/field))
            then <field name="{ manage:generateFieldName($placeName) }">{
                for $query in $existingConfig/query/field/*
                where not(local-name($query) = "key" and $query/@key = $key and $query/@type = $type)
                return $query
            }</field>
            else (),

            for $query in $existingConfig/query/*
            where not(local-name($query) = "key" and $query/@key = $key and $query/@type = $type)
            return $query
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:removeElementFromPlace(
    $placeName as xs:string?,
    $elementName as xs:string,
    $type as xs:string
) as empty-sequence()
{
    let $test := manage:validatePlaceType($type)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            if(exists($existingConfig/query/field))
            then <field name="{ manage:generateFieldName($placeName) }">{
                for $query in $existingConfig/query/field/*
                where not(local-name($query) = "element" and $query/@element = $elementName and $query/@type = $type)
                return $query
            }</field>
            else (),

            for $query in $existingConfig/query/*
            where not(local-name($query) = "element" and $query/@element = $elementName and $query/@type = $type)
            return $query
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:removeAttributeFromPlace(
    $placeName as xs:string?,
    $elementName as xs:string,
    $attributeName as xs:string
) as empty-sequence()
{
    let $test := manage:validateElementName($elementName)
    let $test := manage:validateAttributeName($attributeName)
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            for $query in $existingConfig/query/*
            where not(local-name($query) = "attribute" and $query/@element = $elementName and $query/@attribute = $attributeName)
            return $query
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:removePlaceFromPlace(
    $placeName as xs:string?,
    $subPlaceName as xs:string
) as empty-sequence()
{
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $config := <index>
        { $existingConfig/@* }
        { $existingConfig/options }
        <query>{(
            for $query in $existingConfig/query/*
            where not(local-name($query) = "place" and $query/@name = $subPlaceName)
            return $query
        )}</query>
    </index>
    let $test := manage:checkPlaceConfig($config, $placeName)
    return (
        manage:createFieldForPlace($config),
        config:setPlace($placeName, $config)
    )
};

declare function manage:getPlace(
    $placeName as xs:string?
) as element(json:item)
{
    let $existingConfig := config:getPlace($placeName)
    let $test := manage:checkPlaceConfig($existingConfig, $placeName)
    let $places :=
        for $place in ($existingConfig/query/field/*, $existingConfig/query/* except $existingConfig/query/field)
        return json:object((
            if(local-name($place) = "key")
            then ("key", $place/@key, "type", $place/@type)
            else if(local-name($place) = "element")
            then ("element", $place/@element, "type", $place/@type)
            else if(local-name($place) = "attribute")
            then ("element", $place/@element, "attribute", $place/@attribute)
            else if(local-name($place) = "place")
            then ("place", $place/@name)
            else (),
            "weight", xs:decimal($place/@weight)
        ))
    return
        json:object((
            if(exists($existingConfig/@name))
            then ("name", $existingConfig/@name)
            else (),
            "places", json:array($places)
        ))
};

declare function manage:getAllPlaces(
) as element(json:item)*
{
    for $placeName in config:placeNames()
    return manage:getPlace($placeName)
};


(: Transformers :)
declare function manage:setTransformer(
    $name as xs:string,
    $transformer as xs:string
) as empty-sequence()
{
    let $doc :=
        try {
            xdmp:unquote($transformer, (), ("repair-none", "format-xml"))[1]/*
        }
        catch ($e) {
            error(xs:QName("corona:INVALID-TRANSFORMER"), "Invalid transformer XSLT: parse error")
        }
    let $test :=
        if(local-name($doc) = "stylesheet" and namespace-uri($doc) = "http://www.w3.org/1999/XSL/Transform")
        then ()
        else error(xs:QName("corona:INVALID-TRANSFORMER"), "Invalid transformer, must be an XSLT")
    return xdmp:document-insert(concat("_/transformers/", $name), $doc, xdmp:default-permissions(), $const:TransformersCollection)
};

declare function manage:deleteTransformer(
    $name as xs:string
) as empty-sequence()
{
    if(exists(concat("_/transformers/", $name)))
    then xdmp:document-delete(concat("_/transformers/", $name))
    else ()
};

declare function manage:getTransformer(
    $name as xs:string
) as element()?
{
    doc(concat("_/transformers/", $name))/*
};

declare function manage:getAllTransformerNames(
) as xs:string*
{
    for $transformer in collection($const:TransformersCollection)
    return tokenize(base-uri($transformer), "/")[last()]
};


(: Private functions :)

declare private function manage:createJSONRangeIndex(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    if(exists(manage:getJSONRangeDefinition($key, $type, $config)))
    then ()
    else if($type = "string")
    then
        let $index := admin:database-range-element-index("string", "http://marklogic.com/json", $key, "http://marklogic.com/collation/", false())
        let $config := admin:database-add-range-element-index($config, xdmp:database(), $index)
        return admin:save-configuration($config)
    else if($type = "date")
    then
        let $index := admin:database-range-element-attribute-index("dateTime", "http://marklogic.com/json", $key, "", "normalized-date", "", false())
        let $config := admin:database-add-range-element-attribute-index($config, xdmp:database(), $index)
        return admin:save-configuration($config)
    else if($type = "number")
    then
        let $index := admin:database-range-element-index("decimal", "http://marklogic.com/json", $key, "", false())
        let $config := admin:database-add-range-element-index($config, xdmp:database(), $index)
        return admin:save-configuration($config)
    else if($type = "boolean")
    then
        let $index := admin:database-range-element-attribute-index("string", "http://marklogic.com/json", $key, "", "boolean", "", false())
        let $config := admin:database-add-range-element-attribute-index($config, xdmp:database(), $index)
        return admin:save-configuration($config)
    else ()
};

declare private function manage:createXMLElementRangeIndex(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    let $collation := if($type = "string") then "http://marklogic.com/collation/" else ""
    let $nsLnBits := manage:getNSAndLN($element)
    let $index := admin:database-range-element-index($type, $nsLnBits[1], $nsLnBits[2], $collation, false())
    where empty(manage:getXMLElementRangeDefinition($element, $type, $config))
    return admin:save-configuration(admin:database-add-range-element-index($config, xdmp:database(), $index))
};

declare private function manage:createXMLAttributeRangeIndex(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $config as element()
) as empty-sequence()
{
    let $collation := if($type = "string") then "http://marklogic.com/collation/" else ""
    let $elementNsLnBits := manage:getNSAndLN($element)
    let $attributeNsLnBits := manage:getNSAndLN($attribute)
    let $index := admin:database-range-element-attribute-index($type, $elementNsLnBits[1], $elementNsLnBits[2], $attributeNsLnBits[1], $attributeNsLnBits[2], $collation, false())
    where empty(manage:getXMLAttributeRangeDefinition($element, $attribute, $type, $config))
    return admin:save-configuration(admin:database-add-range-element-attribute-index($config, xdmp:database(), $index))
};


declare private function manage:getJSONRangeDefinition(
    $key as xs:string,
    $type as xs:string,
    $config as element()
) as element()?
{
    manage:getRangeDefinition(<index><structure>json</structure><key>{ $key }</key><type>{ $type }</type></index>, $config)
};

declare private function manage:getXMLElementRangeDefinition(
    $element as xs:string,
    $type as xs:string,
    $config as element()
) as element()?
{
    manage:getRangeDefinition(<index><structure>xmlelement</structure><element>{ $element }</element><type>{ $type }</type></index>, $config)
};

declare private function manage:getXMLAttributeRangeDefinition(
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $config as element()
) as element()?
{
    manage:getRangeDefinition(<index><structure>xmlattribute</structure><element>{ $element }</element><attribute>{ $attribute }</attribute><type>{ $type }</type></index>, $config)
};

declare private function manage:getRangeDefinition(
    $index as element(index),
    $config as element()
) as element()?
{
    if($index/structure = "json")
    then (
        let $xsType := manage:jsonTypeToSchemaType($index/type)
        for $ri in admin:database-get-range-element-indexes($config, xdmp:database())
        where $ri/*:scalar-type = $xsType and $ri/*:namespace-uri = "http://marklogic.com/json" and $ri/*:localname = string($index/key)
        return $ri
        ,
        let $xsType := manage:jsonTypeToSchemaType($index/type)
        for $ri in admin:database-get-range-element-attribute-indexes($config, xdmp:database())
        where $ri/*:scalar-type = $xsType and $ri/*:parent-namespace-uri = "http://marklogic.com/json" and $ri/*:parent-localname = string($index/key)
        return $ri
    )[1]
    else if($index/structure = "xmlelement")
    then (
        let $elementNsLnBits := manage:getNSAndLN($index/element)
        for $ri in admin:database-get-range-element-indexes($config, xdmp:database())
        where $ri/*:scalar-type = string($index/type) and $ri/*:namespace-uri = $elementNsLnBits[1] and $ri/*:localname = $elementNsLnBits[2]
        return $ri
    )[1]
    else if($index/structure = "xmlattribute")
    then (
        let $elementNsLnBits := manage:getNSAndLN($index/element)
        let $attributeNsLnBits := manage:getNSAndLN($index/attribute)
        for $ri in admin:database-get-range-element-attribute-indexes($config, xdmp:database())
        where
            $ri/*:scalar-type = string($index/type)
            and $ri/*:parent-namespace-uri = $elementNsLnBits[1]
            and $ri/*:parent-localname = $elementNsLnBits[2]
            and $ri/*:namespace-uri = $attributeNsLnBits[1]
            and $ri/*:localname = $attributeNsLnBits[2]
        return $ri
    )[1]
    else ()
};

declare private function manage:rangeDefinitionUsedBy(
    $rangeDefinition as element()
) as xs:integer
{
    count(
        for $rangeName in (config:rangeNames(), config:bucketedRangeNames())
        let $index := config:get($rangeName)
        let $structure :=
            if(exists($index/key))
            then "json"
            else if(exists($index/attribute))
            then "xmlattribute"
            else if(exists($index/element))
            then "xmlelement"
            else ()

        let $rangeType :=
            if($structure = "json")
            then
                if($index/type = ("date", "boolean"))
                then "attribute"
                else "element"
            else if($structure = "xmlattribute")
            then "attribute"
            else "element"

        let $xsType :=
            if($structure = "json")
            then manage:jsonTypeToSchemaType($index/type)
            else string($index/type)

        let $elementNsLnBits := if(exists($index/element)) then manage:getNSAndLN($index/element) else ()
        let $attributeNsLnBits := if(exists($index/attribute)) then manage:getNSAndLN($index/attribute) else ()

        let $localname :=
            if($structure = "json")
            then
                if($index/type = "date")
                then "normalized-date"
                else if($index/type = "boolean")
                then "boolean"
                else string($index/key)
            else if($structure = "xmlattribute")
            then $attributeNsLnBits[2]
            else if($structure = "xmlelement")
            then $elementNsLnBits[2]
            else ()
        let $namespace :=
            if($structure = "json")
            then
                if($index/type = ("date", "boolean"))
                then ""
                else "http://marklogic.com/json"
            else if($structure = "xmlattribute")
            then $attributeNsLnBits[1]
            else if($structure = "xmlelement")
            then $elementNsLnBits[1]
            else ""

        let $parentLocalname :=
            if($structure = "json")
            then string($index/key)
            else if($structure = "xmlattribute")
            then $elementNsLnBits[2]
            else ()
        let $parentNamespace :=
            if($structure = "json")
            then "http://marklogic.com/json"
            else if($structure = "xmlattribute")
            then $elementNsLnBits[1]
            else ""

        where
            if($rangeType = "element")
            then
                $rangeDefinition/*:scalar-type = $xsType
                and $rangeDefinition/*:namespace-uri = $namespace
                and $rangeDefinition/*:localname = $localname
            else
                $rangeDefinition/*:scalar-type = $xsType
                and $rangeDefinition/*:parent-namespace-uri = $parentNamespace
                and $rangeDefinition/*:parent-localname = $parentLocalname
                and $rangeDefinition/*:namespace-uri = $namespace
                and $rangeDefinition/*:localname = $localname
        return $index
    )
};

declare private function manage:jsonTypeToSchemaType(
    $type as xs:string?
) as xs:string?
{
    if(empty($type))
    then ()
    else if($type = "string")
    then "string"
    else if($type = "date")
    then "dateTime"
    else "decimal"
};

declare private function manage:getNSAndLN(
    $element as xs:string
) as xs:string+
{
    if(contains($element, ":"))
    then 
        let $el := element { $element } { () }
        return (namespace-uri($el), local-name($el))
    else ("", $element)
};

(: Validation functions :)

declare private function manage:validateIndexName(
    $name as xs:string
) as empty-sequence()
{
    if(not(matches($name, "^[0-9A-Za-z][0-9A-Za-z_-]*$")))
    then error(xs:QName("corona:INVALID-INDEX-NAME"), "Index names can only contain alphanumeric, dash and underscore characters")
    else if(exists(config:get($name)))
    then error(xs:QName("corona:DUPLICATE-INDEX-NAME"), concat("An range index or place with the name '", $name, "' already exists"))
    else ()
};

declare private function manage:validateJSONType(
    $type as xs:string
) as empty-sequence()
{
    if(not($type = ("string", "date", "number")))
    then error(xs:QName("corona:INVALID-DATATYPE"), "Valid JSON types are: string, date and number")
    else ()
};

declare private function manage:validateXMLType(
    $type as xs:string
) as empty-sequence()
{
    if(not($type = ("int", "unsignedInt", "long", "unsignedLong", "float", "double", "decimal", "dateTime", "time", "date", "gYearMonth", "gYear", "gMonth", "gDay", "yearMonthDuration", "dayTimeDuration", "string", "anyURI")))
    then error(xs:QName("corona:INVALID-DATATYPE"), "Valid XML types are: int, unsignedInt, long, unsignedLong, float, double, decimal, dateTime, time, date, gYearMonth, gYear, gMonth, gDay, yearMonthDuration, dayTimeDuration, string and anyURI")
    else ()
};

declare private function manage:validateMode(
    $mode as xs:string
) as empty-sequence()
{
    if(not($mode = ("equals", "textContains", "textEquals")))
    then error(xs:QName("corona:INVALID-MODE"), concat("Modes must be either 'equals', 'textContains' or 'textEquals'. Supplied value was: '", $mode, "'"))
    else ()
};

declare private function manage:validatePlaceType(
    $type as xs:string
) as empty-sequence()
{
    if(not($type = ("include", "exclude")))
    then error(xs:QName("corona:INVALID-TYPE"), concat("Place types must be either 'include' or 'exclude'. Supplied type was: '", $type, "'"))
    else ()
};

declare private function manage:checkForFieldValueCapability(
) as empty-sequence()
{
    try {
        xdmp:function(xs:QName("cts:field-value-query"))
    }
    catch ($e) {
        error(xs:QName("corona:INVALID-MODE"), "This version of MarkLogic Server does not support field value queries.  Upgrade to 5.0 or greater.")
    }
};

declare private function manage:validateElementName(
    $element as xs:string
) as empty-sequence()
{
    try {
        xs:QName($element)[2]
    }
    catch ($e) {
        error(xs:QName("corona:INVALID-XML-ELEMENT-NAME"), concat("Invalid XML element name or undefined namespace prefix: '", $element, "'"))
    }
};

declare private function manage:validateAttributeName(
    $attribute as xs:string
) as empty-sequence()
{
    try {
        xs:QName($attribute)[2]
    }
    catch ($e) {
        error(xs:QName("corona:INVALID-XML-ATTRIBUTE-NAME"), concat("Invalid XML attribute name or undefined namespace prefix: '", $attribute, "'"))
    }
};

declare private function manage:validateBuckets(
    $buckets as element()+,
    $xsType as xs:string
) as empty-sequence()
{
    for $bucket at $pos in $buckets
    return
        if($pos mod 2 = 0 and local-name($bucket) != "boundary" or $pos mod 2 != 0 and local-name($bucket) != "label")
        then error(xs:QName("corona:INVALID-BOUNDS-SEQUENCE"), "Bucket bounds elements need to follow the <label>, <boundary>, <label>, <boundary>, …, <label>, <boundary>, <label> pattern")
        else if(local-name($bucket) = "boundary" and not(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, string($bucket))))
        then error(xs:QName("corona:INVALID-BUCKET-BOUNDARY"), concat("The bucket boundary: '", string($bucket), "' is not of the right datatype"))
        else ()
};

declare private function manage:validateBucketInterval(
    $interval as xs:string
) as empty-sequence()
{
    if(not($interval = ("decade", "year", "quarter", "month", "week", "day", "hour", "minute")))
    then error(xs:QName("corona:INVALID-BUCKET-INTERVAL"), "Valid bucket intervals are: decade, year, quarter, month, week, day, hour and minute")
    else ()
};

declare private function manage:validateStartAndStop(
    $value as xs:anySimpleType?
) as empty-sequence()
{
    if(exists($value) and not($value castable as xs:dateTime))
    then error(xs:QName("corona:INVALID-BUCKET-BOUNDS"), "Bucket starting at and stopping at values must be dateTime values")
    else ()
};

declare private function manage:checkForPlaceLoops(
    $subPlaceName as xs:string,
    $includedPlaces as xs:string*
) as empty-sequence()
{
    let $test :=
        if($subPlaceName = $includedPlaces)
        then error(xs:QName("corona:INVALID-SUB-PLACE"), "A circular reference to an already included place was detected")
        else ()

    let $existingConfig := config:getPlace($subPlaceName)
    for $subSubPlace in $existingConfig/query/place
    return manage:checkForPlaceLoops($subPlaceName, ($includedPlaces, string($subSubPlace/@name)))
};

declare private function manage:checkPlaceConfig(
    $config as element(index)?,
    $placeName as xs:string
) as empty-sequence()
{
    if(empty($config))
    then error(xs:QName("corona:MISSING-PLACE"), concat("The place '", $placeName, "' does not exist"))
    else (),
    if(count($config/query//(element, key)[@type = "exclude"]) > 0 and count($config/query//(element, key)[@type = "include"]) = 0)
    then error(xs:QName("corona:INVALID-PLACE"), "Before specifying a key or element to exclude, at least one key or element must be included")
    else (),
    let $items := ($config/query/field/*, $config/query/* except $config/query/field)
    for $item in $items
    let $duplicateItems :=
        if(exists($item/@attribute))
        then $items[@element = $item/@element][@attribute = $item/@attribute]
        else if(exists($item/@element))
        then $items[@element = $item/@element][@type = $item/@type]
        else if(exists($item/@key))
        then $items[@key = $item/@key][@type = $item/@type]
        else if(exists($item/@name))
        then $items[@name = $item/@name]
        else ()
    let $description :=
        if(exists($item/@attribute))
        then concat("with element name ", string($item/@element), " and attribute name ", string($item/@attribute))
        else if(exists($item/@place))
        then concat("named ", string($item/@name))
        else concat("named ", string($item/(@element, @key)), if($item/@type = "exclude") then " (excluded)" else " (included)")
    where count($duplicateItems) > 1
    return error(xs:QName("corona:DUPLICATE-PLACE-ITEM"), concat("The ", local-name($item), " ", $description, " is already configured"))
};

declare private function manage:generateFieldName(
    $placeName as xs:string?
) as xs:string
{
    if(empty($placeName))
    then "corona-field--anonymous"
    else concat("corona-field-", $placeName)
};

declare private function manage:createFieldForPlace(
    $config as element(index)
) as empty-sequence()
{
    let $fieldName := manage:generateFieldName($config/@name)
    let $database := xdmp:database()
    let $dbConfig := admin:get-configuration()
    let $existing :=
        try {
            admin:database-get-field($dbConfig, $database, $fieldName)
        }
        catch ($e) {()}
    let $dbConfig :=
        if(exists($existing))
        then admin:database-delete-field($dbConfig, $database, $fieldName)
        else $dbConfig
    let $dbConfig := admin:database-add-field($dbConfig, $database, admin:database-field($fieldName, false()))

    let $add :=
        for $item in $config/query/field/*[@type = "include"]
        let $nsLnBits :=
            if(local-name($item) = "element")
            then manage:getNSAndLN($item/@element)
            else ("http://marklogic.com/json", json:escapeNCName($item/@key))
        let $el := admin:database-included-element($nsLnBits[1], $nsLnBits[2], ($item/@weight, 1)[1], (), "", "")
        return xdmp:set($dbConfig, admin:database-add-field-included-element($dbConfig, $database, $fieldName, $el))
    let $add :=
        for $item in $config/query/field/*[@type = "exclude"]
        let $nsLnBits :=
            if(local-name($item) = "element")
            then manage:getNSAndLN($item/@element)
            else ("http://marklogic.com/json", json:escapeNCName($item/@key))
        let $el := admin:database-excluded-element($nsLnBits[1], $nsLnBits[2])
        return xdmp:set($dbConfig, admin:database-add-field-excluded-element($dbConfig, $database, $fieldName, $el))

    return admin:save-configuration($dbConfig)
};
