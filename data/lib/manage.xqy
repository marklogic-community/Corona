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

module namespace manage="http://marklogic.com/mljson/manage";

import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace config="http://marklogic.com/mljson/index-config" at "index-config.xqy";
import module namespace const="http://marklogic.com/mljson/constants" at "constants.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace db="http://marklogic.com/xdmp/database";
declare default function namespace "http://www.w3.org/2005/xpath-functions";



(: Fields :)
declare function manage:createField(
    $name as xs:string,
    $includeKeys as xs:string*,
    $excludeKeys as xs:string*,
    $includeElements as xs:string*,
    $excludeElements as xs:string*,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test :=
        for $element in ($includeElements, $excludeElements)
        return manage:validateElementName($element)
    let $test :=
        if(empty($includeKeys) and empty($includeElements))
        then error(xs:QName("manage:MISSING-KEY-OR-ELEMENT"), "Must supply at least one JSON key or XML element to be included in the field")
        else ()

    let $database := xdmp:database()
    let $config := admin:database-add-field($config, $database, admin:database-field($name, false()))
    let $add :=
        for $include in $includeKeys[string-length(.) > 0]
        let $include := json:escapeNCName($include)
        let $el := admin:database-included-element("http://marklogic.com/json", $include, 1, (), "", "")
        return xdmp:set($config, admin:database-add-field-included-element($config, $database, $name, $el))
    let $add :=
        for $exclude in $excludeKeys[string-length(.) > 0]
        let $exclude := json:escapeNCName($exclude)
        let $el := admin:database-excluded-element("http://marklogic.com/json", $exclude)
        return xdmp:set($config, admin:database-add-field-excluded-element($config, $database, $name, $el))

    let $add :=
        for $include in $includeElements[string-length(.) > 0]
        let $nsLnBits := manage:getNSAndLN($include)
        let $el := admin:database-included-element($nsLnBits[1], $nsLnBits[2], 1, (), "", "")
        return xdmp:set($config, admin:database-add-field-included-element($config, $database, $name, $el))
    let $add :=
        for $exclude in $excludeElements[string-length(.) > 0]
        let $nsLnBits := manage:getNSAndLN($exclude)
        let $el := admin:database-excluded-element($nsLnBits[1], $nsLnBits[2])
        return xdmp:set($config, admin:database-add-field-excluded-element($config, $database, $name, $el))
    return admin:save-configuration($config)
    ,
    config:setField($name)
};

declare function manage:deleteField(
    $name as xs:string,
    $config as element()
) as empty-sequence()
{
    admin:save-configuration(admin:database-delete-field($config, xdmp:database(), $name)),
    config:delete($name)
};

declare function manage:getField(
    $name as xs:string,
    $config as element()
) as element(json:item)?
{
    let $database := xdmp:database()
    let $def :=
        try {
            admin:database-get-field($config, $database, $name)
        }
        catch ($e) {()}
    where exists($def)
    return manage:fieldDefinitionToJsonXml($def)
};

declare function manage:getAllFields(
    $config as element()
) as element(json:item)*
{
    let $database := xdmp:database()
    let $config := admin:get-configuration()
    for $field in admin:database-get-fields($config, $database)
    where string-length($field/*:field-name) > 0
    return manage:fieldDefinitionToJsonXml($field)
};


(: Maps :)
declare function manage:createJSONMap(
    $name as xs:string,
    $key as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateMode($mode)
    return config:setJSONMap($name, json:escapeNCName($key), $mode)
};

declare function manage:createXMLMap(
    $name as xs:string,
    $element as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateMode($mode)
    return config:setXMLMap($name, $element, $mode)
};

declare function manage:deleteMap(
    $name as xs:string
) as empty-sequence()
{
    config:delete($name)
};

declare function manage:getMap(
    $name as xs:string
) as element(json:item)?
{
    let $index := config:get($name)
    let $type := string($index/structure)
    let $mode := string($index/mode)
    where $index/@type = "map"
    return
        if($type = "json")
        then json:object((
            "name", $name,
            "type", $type,
            "key", string($index/key),
            "mode", $mode
        ))
        else json:object((
            "name", $name,
            "type", $type,
            "element", string($index/element),
            "mode", $mode
        ))
};

declare function manage:getAllMaps(
) as element(json:item)*
{
    for $mapName in config:mapNames()
    return manage:getMap($mapName)
};


(: Ranges :)
declare function manage:createJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $operator as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateJSONType($type)
    let $test := manage:validateOperator($operator)

    let $key := json:escapeNCName($key)
    let $operator :=
        if($type = "boolean")
        then "eq"
        else $operator
    return (
        manage:createJSONRangeIndex($name, $key, $type, $config),
        config:setJSONRange($name, $key, $type, $operator)
    )
};

declare function manage:createXMLElementRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $operator as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateOperator($operator)

    return (
        manage:createXMLElementRangeIndex($name, $element, $type, $config),
        config:setXMLElementRange($name, $element, $type, $operator)
    )
};

declare function manage:createXMLAttributeRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $operator as xs:string,
    $config as element()
) as empty-sequence()
{
    let $test := manage:validateIndexName($name)
    let $test := manage:validateElementName($element)
    let $test := manage:validateAttributeName($attribute)
    let $test := manage:validateXMLType($type)
    let $test := manage:validateOperator($operator)

    return (
        manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config),
        config:setXMLAttributeRange($name, $element, $attribute, $type, $operator)
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
                "type", string($index/type),
                "operator", if($index/type = "boolean") then "eq" else string($index/operator)
            ))
        else if($index/structure = "xmlelement")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "type", string($index/type),
                "operator", string($index/operator)
            ))
        else if($index/structure = "xmlattribute")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "attribute", string($index/attribute),
                "type", string($index/type),
                "operator", string($index/operator)
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

(: Content items :)
declare function manage:addContentItem(
    $type as xs:string,
    $name as xs:string,
    $mode as xs:string,
    $weight as xs:decimal
) as empty-sequence()
{
    let $test :=
        if($type = "field" and $mode = "equals")
        then
            try {
                xdmp:function("cts:field-value-query")
            }
            catch ($e) {
                error(xs:QName("manage:INVALID-MODE"), "This version of MarkLogic Server does not support field value queries.  Upgrade to 5.0 or greater.")
            }
        else ()
    let $QName :=
        if($type = "key")
        then json:escapeNCName($name)
        else if($type = "element")
        then (
            manage:validateElementName($name),
            $name
        )
        else $name
    let $existing := config:getContentItems()
    let $new := (
        for $item in $existing
        where not($item/@type = $type and $item = $QName and $item/@mode = $mode) or exists($item/@element)
        return $item
        ,
        <item type="{ $type }" weight="{ $weight }" mode="{ $mode }">{ $QName }</item>
    )
    return config:setContentItems($new)
};

declare function manage:addContentItem(
    $type as xs:string,
    $elementName as xs:string,
    $attributeName as xs:string,
    $mode as xs:string,
    $weight as xs:decimal
) as empty-sequence()
{
    let $test := manage:validateElementName($elementName)
    let $test := manage:validateAttributeName($attributeName)
    let $existing := config:getContentItems()
    let $new := (
        for $item in $existing
        where not($item/@type = $type and $item/@element = $elementName and $item = $attributeName and $item/@mode = $mode) or empty($item/@element)
        return $item
        ,
        <item type="attribute" element="{ $elementName }" weight="{ $weight }" mode="{ $mode }">{ $attributeName }</item>
    )
    return config:setContentItems($new)
};

declare function manage:deleteContentItem(
    $type as xs:string,
    $name as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    let $QName :=
        if($type = "key")
        then json:escapeNCName($name)
        else $name
    let $new :=
        for $item in config:getContentItems()
        where not($item/@type = $type and $item = $QName and $item/@mode = $mode)
        return $item
    return config:setContentItems($new)
};

declare function manage:deleteContentItem(
    $type as xs:string,
    $elementName as xs:string,
    $attributeName as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    config:setContentItems(
        for $item in config:getContentItems()
        where not($item/@type = $type and $item/@element = $elementName and $item = $attributeName and $item/@mode = $mode)
        return $item
    )
};

declare function manage:getContentItem(
    $type as xs:string,
    $name as xs:string,
    $mode as xs:string
) as element(json:item)?
{
    let $QName :=
        if($type = "key")
        then json:escapeNCName($name)
        else $name
    for $item in config:getContentItems()
    where $item/@type = $type and $item = $QName and $item/@mode = $mode
    return json:object((
        string($item/@type), $name,
        "weight", xs:decimal($item/@weight)
    ))
};

declare function manage:getContentItem(
    $type as xs:string,
    $elementName as xs:string,
    $attributeName as xs:string,
    $mode as xs:string
) as element(json:item)?
{
    for $item in config:getContentItems()
    where $item/@type = $type and $item/@element = $elementName and $item = $attributeName and $item/@mode = $mode
    return json:object((
        "element", $elementName,
        "attribute", $attributeName,
        "weight", xs:decimal($item/@weight)
    ))
};

declare function manage:getAllContentItems(
) as element(json:item)*
{
    for $item in config:getContentItems()
    let $name :=
        if($item/@type = "key")
        then json:unescapeNCName($item)
        else string($item)
    return json:object((
        if($item/@type = "attribute")
        then ("element", string($item/@element))
        else (),
        string($item/@type), $name,
        "mode", string($item/@mode),
        "weight", xs:decimal($item/@weight)
    ))
};


(: Private functions :)

declare private function manage:getPrefixForNamespaceURI(
    $uri as xs:string
) as xs:string?
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    for $namespace in admin:group-get-namespaces($config, $group)
    where string($namespace/*:namespace-uri) = $uri
    return string($namespace/*:prefix)
};

declare private function manage:fieldDefinitionToJsonXml(
    $field as element(db:field)
) as element(json:item)
{
    json:object((
        "name", string($field/db:field-name),
        "includedKeys", json:array(
            for $include in $field/db:included-elements/db:included-element
            for $key in tokenize(string($include/db:localname), " ")
            return
                if($include/db:namespace-uri = "http://marklogic.com/json")
                then json:object((
                    "type", "key",
                    "name", json:unescapeNCName($key)
                ))
                else json:object((
                    "type", "element",
                    "name", if(string-length($include/db:namespace-uri)) then concat(manage:getPrefixForNamespaceURI(string($include/db:namespace-uri)), ":", $key) else $key
                ))
        ),
        "excludedKeys", json:array(
            for $exclude in $field/db:excluded-elements/db:excluded-element
            for $key in tokenize(string($exclude/db:localname), " ")
            return
                if($exclude/db:namespace-uri = "http://marklogic.com/json")
                then json:object((
                    "type", "key",
                    "name", json:unescapeNCName($key)
                ))
                else json:object((
                    "type", "element",
                    "name", if(string-length($exclude/db:namespace-uri)) then concat(manage:getPrefixForNamespaceURI(string($exclude/db:namespace-uri)), ":", $key) else $key
                ))
        )
    ))
};

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

declare function manage:createXMLElementRangeIndex(
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

declare function manage:createXMLAttributeRangeIndex(
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
            error(xs:QName("manage:INVALID-TRANSFORMER"), "Invalid transformer XSLT: parse error")
        }
    let $test :=
        if(local-name($doc) = "stylesheet" and namespace-uri($doc) = "http://www.w3.org/1999/XSL/Transform")
        then ()
        else error(xs:QName("manage:INVALID-TRANSFORMER"), "Invalid transformer, must be an XSLT")
    return xdmp:document-insert(concat("/transformers/", $name), $doc, xdmp:default-permissions(), $const:TransformersCollection)
};

declare function manage:deleteTransformer(
    $name as xs:string
) as empty-sequence()
{
    if(exists(concat("/transformers/", $name)))
    then xdmp:document-delete(concat("/transformers/", $name))
    else ()
};

declare function manage:getTransformer(
    $name as xs:string
) as element()?
{
    doc(concat("/transformers/", $name))/*
};

declare function manage:getAllTransformerNames(
) as xs:string*
{
    for $transformer in collection($const:TransformersCollection)
    return tokenize(base-uri($transformer), "/")[last()]
};


(: Private functions :)

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

declare private function manage:schemaTypeToJsonType(
    $type as xs:string?
) as xs:string?
{
    if(empty($type))
    then ()
    else if($type = "string")
    then "string"
    else if($type = "dateTime")
    then "date"
    else if($type = "boolean")
    then "boolean"
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
    if(not(matches($name, "^[0-9A-Za-z_-]+$")))
    then error(xs:QName("manage:INVALID-INDEX-NAME"), "Index names can only contain alphanumeric, dash and underscore characters")
    else if(exists(config:get($name)))
    then error(xs:QName("manage:DUPLICATE-INDEX-NAME"), concat("An index, field or alias with the name '", $name, "' already exists"))
    else ()
};

declare private function manage:validateJSONType(
    $type as xs:string
) as empty-sequence()
{
    if(not($type = ("string", "date", "number")))
    then error(xs:QName("manage:INVALID-DATATYPE"), "Valid JSON types are: string, date and number")
    else ()
};

declare private function manage:validateXMLType(
    $type as xs:string
) as empty-sequence()
{
    if(not($type = ("int", "unsignedInt", "long", "unsignedLong", "float", "double", "decimal", "dateTime", "time", "date", "gYearMonth", "gYear", "gMonth", "gDay", "yearMonthDuration", "dayTimeDuration", "string", "anyURI")))
    then error(xs:QName("manage:INVALID-DATATYPE"), "Valid XML types are: int, unsignedInt, long, unsignedLong, float, double, decimal, dateTime, time, date, gYearMonth, gYear, gMonth, gDay, yearMonthDuration, dayTimeDuration, string and anyURI")
    else ()
};

declare private function manage:validateOperator(
    $operator as xs:string
) as empty-sequence()
{
    if(not($operator = ("eq", "ne", "lt", "le", "gt", "ge")))
    then error(xs:QName("manage:INVALID-OPERATOR"), "Valid operators are: eq, ne, lt, le, gt and ge")
    else ()
};

declare private function manage:validateMode(
    $mode as xs:string
) as empty-sequence()
{
    if(not($mode = ("equals", "contains")))
    then error(xs:QName("manage:INVALID-MODE"), "Map modes must be either 'equals' or 'contains'")
    else ()
};

declare private function manage:validateElementName(
    $element as xs:string
) as empty-sequence()
{
    try {
        xs:QName($element)[2]
    }
    catch ($e) {
        error(xs:QName("manage:INVALID-XML-ELEMENT-NAME"), concat("Invalid XML element name or undefined namespace prefix: '", $element, "'"))
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
        error(xs:QName("manage:INVALID-XML-ATTRIBUTE-NAME"), concat("Invalid XML attribute name or undefined namespace prefix: '", $attribute, "'"))
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
        then error(xs:QName("manage:INVALID-BOUNDS-SEQUENCE"), "Bucket bounds elements need to follow the <label>, <boundary>, <label>, <boundary>, …, <label>, <boundary>, <label> pattern")
        else if(local-name($bucket) = "boundary" and not(xdmp:castable-as("http://www.w3.org/2001/XMLSchema", $xsType, string($bucket))))
        then error(xs:QName("manage:INVALID-BUCKET-BOUNDARY"), concat("The bucket boundary: '", string($bucket), "' is not of the right datatype"))
        else ()
};

declare private function manage:validateBucketInterval(
    $interval as xs:string
) as empty-sequence()
{
    if(not($interval = ("decade", "year", "quarter", "month", "week", "day", "hour", "minute")))
    then error(xs:QName("manage:INVALID-BUCKET-INTERVAL"), "Valid bucket intervals are: decade, year, quarter, month, week, day, hour and minute")
    else ()
};

declare private function manage:validateStartAndStop(
    $value as xs:anySimpleType?
) as empty-sequence()
{
    if(exists($value) and not($value castable as xs:dateTime))
    then error(xs:QName("manage:INVALID-BUCKET-BOUNDS"), "Bucket starting at and stopping at values must be dateTime values")
    else ()
};
