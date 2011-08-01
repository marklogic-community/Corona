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
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace db="http://marklogic.com/xdmp/database";
declare default function namespace "http://www.w3.org/2005/xpath-functions";



declare function manage:validateIndexName(
    $name as xs:string?
) as xs:string?
{
    if(empty($name) or string-length($name) = 0)
    then "Must provide a name for the index"
    else if(not(matches($name, "^[0-9A-Za-z_-]+$")))
    then "Index names can only contain alphanumeric, dash and underscore characters"
    else if(exists(config:get($name)))
    then concat("An index, field or alias with the name '", $name, "' already exists")
    else ()
};


declare function manage:createField(
    $name as xs:string,
    $includeKeys as xs:string*,
    $excludeKeys as xs:string*,
    $includeElements as xs:string*,
    $excludeElements as xs:string*,
    $config as element()
) as empty-sequence()
{
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


declare function manage:createJSONMap(
    $name as xs:string,
    $key as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    config:setJSONMap($name, json:escapeNCName($key), $mode)
};

declare function manage:createXMLMap(
    $name as xs:string,
    $element as xs:string,
    $mode as xs:string
) as empty-sequence()
{
    config:setXMLMap($name, $element, $mode)
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


declare function manage:createJSONRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $operator as xs:string,
    $config as element()
) as empty-sequence()
{
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
    manage:createXMLElementRangeIndex($name, $element, $type, $config)
    ,
    config:setXMLElementRange($name, $element, $type, $operator)
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
    manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config)
    ,
    config:setXMLAttributeRange($name, $element, $attribute, $type, $operator)
};

(: XXX - should not delete the range index if other ranges are using it :)
declare function manage:deleteRange(
    $name as xs:string,
    $config as element()
) as empty-sequence()
{
    let $database := xdmp:database()
    let $index := config:get($name)
    let $existing := manage:getRangeDefinition($index, $config)
    where $index/@type = "range"
    return (
        if(exists($existing))
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


declare function manage:createJSONBucketedRange(
    $name as xs:string,
    $key as xs:string,
    $type as xs:string,
    $buckets as element()+,
    $config as element()
) as empty-sequence()
{
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
    $units as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $config as element()
) as empty-sequence()
{
    let $key := json:escapeNCName($key)
    return (
        manage:createJSONRangeIndex($name, $key, $type, $config),
        config:setJSONAutoBucketedRange($name, $key, $type, $units, $startingAt, $stoppingAt)
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
    manage:createXMLElementRangeIndex($name, $element, $type, $config)
    ,
    config:setXMLElementBucketedRange($name, $element, $type, $buckets)
};

declare function manage:createXMLElementAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $type as xs:string,
    $units as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $config as element()
) as empty-sequence()
{
    manage:createXMLElementRangeIndex($name, $element, $type, $config)
    ,
    config:setXMLElementAutoBucketedRange($name, $element, $type, $units, $startingAt, $stoppingAt)
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
    manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config)
    ,
    config:setXMLAttributeBucketedRange($name, $element, $attribute, $type, $buckets)
};

declare function manage:createXMLAttributeAutoBucketedRange(
    $name as xs:string,
    $element as xs:string,
    $attribute as xs:string,
    $type as xs:string,
    $units as xs:string,
    $startingAt as xs:anySimpleType,
    $stoppingAt as xs:anySimpleType?,
    $config as element()
) as empty-sequence()
{
    manage:createXMLAttributeRangeIndex($name, $element, $attribute, $type, $config)
    ,
    config:setXMLAttributeAutoBucketedRange($name, $element, $attribute, $type, $units, $startingAt, $stoppingAt)
};

(: XXX - should not delete the range index if other ranges are using it :)
declare function manage:deleteBucketedRange(
    $name as xs:string,
    $config as element()
) as empty-sequence()
{
    let $database := xdmp:database()
    let $index := config:get($name)
    let $existing := manage:getRangeDefinition($index, $config)
    let $log := xdmp:log($index)
    where $index/@type = ("bucketedrange", "autobucketedrange")
    return (
        if(exists($existing))
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
    where $index/@type = ("bucketedrange", "autobucketedrange")
    return
        if($index/structure = "json")
        then
            json:object((
                "name", $name,
                "key", json:unescapeNCName($index/key),
                "type", string($index/type),
                if(exists($index/buckets))
                then ("buckets", json:array(for $bucket in $index/buckets/* return string($bucket)))
                else (),
                if(exists($index/units))
                then ("units", string($index/units))
                else (),
                if(exists($index/startingAt))
                then ("startingAt", string($index/startingAt))
                else (),
                if(exists($index/stoppingAt))
                then ("stoppingAt", string($index/stoppingAt))
                else ()
            ))
        else if($index/structure = "xmlelement")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "type", string($index/type),
                if(exists($index/buckets))
                then ("buckets", json:array(for $bucket in $index/buckets/* return string($bucket)))
                else (),
                if(exists($index/units))
                then ("units", string($index/units))
                else (),
                if(exists($index/startingAt))
                then ("startingAt", string($index/startingAt))
                else (),
                if(exists($index/stoppingAt))
                then ("stoppingAt", string($index/stoppingAt))
                else ()
            ))
        else if($index/structure = "xmlattribute")
        then
            json:object((
                "name", $name,
                "element", string($index/element),
                "attribute", string($index/attribute),
                "type", string($index/type),
                if(exists($index/buckets))
                then ("buckets", json:array(for $bucket in $index/buckets/* return string($bucket)))
                else (),
                if(exists($index/units))
                then ("units", string($index/units))
                else (),
                if(exists($index/startingAt))
                then ("startingAt", string($index/startingAt))
                else (),
                if(exists($index/stoppingAt))
                then ("stoppingAt", string($index/stoppingAt))
                else ()
            ))
        else ()
};

declare function manage:getAllBucketedRanges(
) as element(json:item)*
{
    for $name in config:bucketedRangeNames()
    return manage:getBucketedRange($name)
};


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
        (: XXX - don't think we can create range indexes of type boolean :)
        let $index := admin:database-range-element-attribute-index("boolean", "http://marklogic.com/json", $key, "", "boolean", "", false())
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
    manage:getRangeDefinition(<index><structure>xmlelement</structure><element>{ $element }</element><attribute>{ $attribute }</attribute><type>{ $type }</type></index>, $config)
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
        where $ri/*:scalar-type = string($ri/type) and $ri/*:namespace-uri = $elementNsLnBits[1] and $ri/*:localname = $elementNsLnBits[2]
        return $ri
    )[1]
    else if($index/structure = "xmlattribute")
    then (
        let $elementNsLnBits := manage:getNSAndLN($index/element)
        let $attributeNsLnBits := manage:getNSAndLN($index/attribute)
        for $ri in admin:database-get-range-element-indexes($config, xdmp:database())
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
