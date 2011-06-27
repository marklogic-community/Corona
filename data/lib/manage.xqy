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
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace db="http://marklogic.com/xdmp/database";
declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function manage:fieldDefinitionToJsonXml(
    $field as element(db:field)
) as element(item)
{
    <item type="object">
        <name type="string">{ string($field/db:field-name) }</name>
        <includedKeys type="array">{
            for $include in $field/db:included-elements/db:included-element
            for $key in tokenize(string($include/db:localname), " ")
            return <item type="string">{ json:unescapeNCName($key) }</item>
        }</includedKeys>
        <excludedKeys type="array">{
            for $include in $field/db:excluded-elements/db:exclude-element
            for $key in tokenize(string($include/db:localname), " ")
            return <item type="string">{ json:unescapeNCName($key) }</item>
        }</excludedKeys>
    </item>
};
