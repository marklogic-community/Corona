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
import module namespace prop="http://xqdev.com/prop" at "properties.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace db="http://marklogic.com/xdmp/database";
declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function manage:fieldDefinitionToJsonXml(
    $field as element(db:field)
) as element(json:item)
{
    json:object((
        "name", string($field/db:field-name),
        "includedKeys", json:array(
            for $include in $field/db:included-elements/db:included-element
            for $key in tokenize(string($include/db:localname), " ")
            return json:unescapeNCName($key)
        ),
        "excludedKeys", json:array(
            for $include in $field/db:excluded-elements/db:exclude-element
            for $key in tokenize(string($include/db:localname), " ")
            return json:unescapeNCName($key)
        )
    ))
};

declare function manage:rangeDefinitionToJsonXml(
    $index as element(),
    $name as xs:string,
    $operator as xs:string
) as element(json:item)
{
    json:object((
        "name", $name,
        "key", json:unescapeNCName(string($index/*:localname)),
        "type", string($index/*:scalar-type),
        "operator", $operator
    ))
};

declare function manage:validateIndexName(
    $name as xs:string?
) as xs:string?
{
    if(empty($name) or string-length($name) = 0)
    then "Must provide a name for the index"
    else if(not(matches($name, "^[0-9A-Za-z_-]+$")))
    then "Index names can only contain alphanumeric, dash and underscore characters"
    else if(exists(prop:get(concat("index-", $name))))
    then concat("An index, field or alias with the name '", $name, "' already exists")
    else ()
};

declare function manage:jsonTypeToSchemaType(
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

declare function manage:getRangeIndexProperties(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and starts-with($value, "range/")
    return $value
};

declare function manage:getMappingProperties(
) as xs:string*
{
    for $key in prop:all()
    let $value := prop:get($key)
    where starts-with($key, "index-") and starts-with($value, "map/")
    return $value
};

declare function manage:getPropertiesAssociatedWithRangeIndex(
    $index as element()
) as xs:string*
{
    for $value in manage:getRangeIndexProperties()
    let $bits := tokenize($value, "/")
    let $key := $bits[3]
    let $type := $bits[4]
    where $index/*:scalar-type = manage:jsonTypeToSchemaType($type) and $index/(*:namespace-uri, *:parent-namespace-uri) = "http://marklogic.com/json" and $index/(*:localname, *:parent-localname) = $key
    return $value
};

declare function manage:getRangeDefinitions(
) as element(json:item)*
{
    let $config := admin:get-configuration()
    let $existingElementIndexes := admin:database-get-range-element-indexes($config, xdmp:database())
    let $existingAttributeIndexes := admin:database-get-range-element-attribute-indexes($config, xdmp:database())

    for $value in manage:getRangeIndexProperties()
    let $bits := tokenize($value, "/")
    let $name := $bits[2]
    let $key := $bits[3]
    let $type := manage:jsonTypeToSchemaType($bits[4])
    let $operator := $bits[5]
    let $index := (
        for $index in $existingElementIndexes
        where $index/db:scalar-type = $type and $index/db:namespace-uri = "http://marklogic.com/json" and $index/db:localname = $key
        return $index
        ,
        for $index in $existingAttributeIndexes
        where $index/db:scalar-type = $type and $index/db:parent-namespace-uri = "http://marklogic.com/json" and $index/db:parent-localname = $key
        return $index
    )
    return manage:rangeDefinitionToJsonXml($index, $name, $operator)
};
