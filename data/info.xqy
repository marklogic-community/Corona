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

import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";

let $config := admin:get-configuration()
let $database := xdmp:database()
let $json :=
<json type="object">
    <version type="string">{ xdmp:version() }</version>
    <architecture type="string">{ xdmp:architecture() }</architecture>
    <platform type="string">{ xdmp:platform() }</platform>
    <hosts type="array">{
        for $host in xdmp:hosts()
        return <item type="object">
            <id type="number">{ $host }</id>
            <name type="string">{ xdmp:host-name($host) }</name>
        </item>
    }</hosts>
    <indexes type="object">
        <stemming type="string">{ admin:database-get-stemmed-searches($config, $database) }</stemming>
        <uris boolean="{ admin:database-get-uri-lexicon($config, $database) }"/>
        <collectionLexicon boolean="{ admin:database-get-collection-lexicon($config, $database) }"/>
        <caseSensitive boolean="{ admin:database-get-fast-case-sensitive-searches($config, $database) }"/>
        <diacriticSensitive boolean="{ admin:database-get-fast-diacritic-sensitive-searches($config, $database) }"/>
        <keyValueCharacters boolean="{ admin:database-get-fast-element-character-searches($config, $database) }"/>
        <keyValueWords boolean="{ admin:database-get-fast-element-word-searches($config, $database) }"/>
        <keyValuePhrases boolean="{ admin:database-get-fast-element-phrase-searches($config, $database) }"/>
        <keyValueTrailingWildcards boolean="{ admin:database-get-fast-element-trailing-wildcard-searches($config, $database) }"/>
        <geo type="array">
        </geo>
        <keyValueRanges type="array">{
            for $index in admin:database-get-range-element-indexes($config, $database)
            for $key in tokenize(string($index/*:localname), " ")
            where string-length(string($index/*:namespace-uri)) = 0
            return <item type="object">
                <type type="string">{ string($index/*:scalar-type) }</type>
                <key type="string">{ $key }</key>
                { if($index/*:scalar-type = "string") then <collation type="string">{ string($index/*:collation) }</collation> else () }
            </item>
        }</keyValueRanges>
        <fields type="array">{
            for $field in admin:database-get-fields($config, $database)
            where string-length(string($field/*:name))
            return <item type="object">
                <name type="string">{ string($field/*:name) }</name>
                <includedKeys type="array">{
                    for $key in tokenize(string($field/*:included-elements), " ")
                    return <item type="string">{ $key }</item>
                }</includedKeys>
                <excludedKeys type="array">{
                    for $key in tokenize(string($field/*:excluded-elements), " ")
                    return <item type="string">{ $key }</item>
                }</excludedKeys>
            </item>
        }</fields>
    </indexes>
    <settings type="object">
        <directoryCreation type="string">{ admin:database-get-directory-creation($config, $database) }</directoryCreation>
    </settings>
</json>

return json:xmlToJSON($json)
