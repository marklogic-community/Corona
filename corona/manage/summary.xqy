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

import module namespace json="http://marklogic.com/json" at "../lib/json.xqy";
import module namespace pathparser="http://marklogic.com/mljson/path-parser" at "../lib/path-parser.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "../lib/date-parser.xqy";
import module namespace common="http://marklogic.com/corona/common" at "../lib/common.xqy";
import module namespace manage="http://marklogic.com/corona/manage" at "../lib/manage.xqy";
import module namespace const="http://marklogic.com/corona/constants" at "../lib/constants.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";

let $config := admin:get-configuration()
let $database := xdmp:database()

let $requestMethod := xdmp:get-request-method()
let $numJSONDocs := xdmp:estimate(/json:json)
let $numTextDocs := xdmp:estimate(doc()/text())
let $numBinaryDocs := xdmp:estimate(doc()/binary())
let $numXMLDocs := xdmp:estimate(/*) - $numJSONDocs

return common:output(
    if($requestMethod = "GET")
    then json:document(
        json:object((
            "isManaged", manage:isManaged(),
            "defaultOutputFormat", manage:defaultOutputFormat(),
            "insertTransformsEnabled", manage:insertTransformsEnabled(),
            "fetchTransformsEnabled", manage:fetchTransformsEnabled(),
            "features", json:object((
                "JSONDocs", json:isSupported(),
                "JSONPath", pathparser:supportedFormats() = "json",
                "dateParsing", dateparser:isSupported(),
                "simplifiedXPath", pathparser:supportedFormats() = "xpath"
            )),
            "libraryVersion", $const:version,
            "serverVersion", xdmp:version(),
            "architecture", xdmp:architecture(),
            "platform", xdmp:platform(),
            "hosts", json:array((
                for $host in xdmp:hosts()
                return json:object((
                    "id", $host,
                    "name", xdmp:host-name($host)
                ))
            )),
            "indexes", json:object((
                "stemming", admin:database-get-stemmed-searches($config, $database),
                "uris", admin:database-get-uri-lexicon($config, $database),
                "collectionLexicon", admin:database-get-collection-lexicon($config, $database),
                "caseSensitive", admin:database-get-fast-case-sensitive-searches($config, $database),
                "diacriticSensitive", admin:database-get-fast-diacritic-sensitive-searches($config, $database),
                "keyValueCharacters", admin:database-get-fast-element-character-searches($config, $database),
                "keyValueWords", admin:database-get-fast-element-word-searches($config, $database),
                "keyValuePhrases", admin:database-get-fast-element-phrase-searches($config, $database),
                "keyValueTrailingWildcards", admin:database-get-fast-element-trailing-wildcard-searches($config, $database),
                "ranges", json:array(manage:getAllRanges()),
                "bucketedRanges", json:array(manage:getAllBucketedRanges()),
                "places", json:array(manage:getAllPlaces()),
                "geo", json:array(manage:getAllGeos()),
                "anonymousPlace", manage:getPlace(())
            )),
            "transformers", json:array(manage:getAllTransformerNames()),
            "namedQueryPrefixes", json:array(manage:getNamedQueryPrefixes()),
            "statistics", json:object((
                "XMLDocumentCount", $numXMLDocs,
                "JSONDocumentCount", $numJSONDocs,
                "TextDocumentCount", $numTextDocs,
                "BinaryDocumentCount", $numBinaryDocs
            )),
            "xmlNamespaces", json:array(manage:getAllNamespaces())
        ))
    )
    else if($requestMethod = "DELETE")
    then (
            manage:deleteAllRanges(),
            manage:deleteAllBucketedRanges(),
            manage:deleteAllPlaces(),
            manage:deleteAllGeos(),
            manage:deleteAllTransformers(),
            manage:deleteAllNamespaces()
    )
    else ()
)
