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

module namespace common="http://marklogic.com/mljson/common";
import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace reststore="http://marklogic.com/reststore" at "reststore.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function common:error(
    $statusCode as xs:integer,
    $message as xs:string
) as xs:string
{
    let $set := xdmp:set-response-code($statusCode, $message)
    let $add := xdmp:add-response-header("Date", string(current-dateTime()))
    let $response :=
        json:document(
            json:object((
                "error", json:object((
                    "code", $statusCode,
                    "message", $message
                ))
            ))
        )
    return json:xmlToJSON($response)
};

declare function common:outputMultipleDocs(
    $docs as element(json:json)*,
    $start as xs:integer,
    $end as xs:integer?,
    $total as xs:integer,
    $include as xs:string*,
    $query as cts:query?
) as xs:string
{
    let $end :=
        if(empty($end))
        then $start
        else $end

    return json:xmlToJSON(
        json:object((
            "meta", json:object((
                "start", $start,
                "end", $end,
                "total", $total
            )),
            "results", json:array(
                for $doc in $docs
                let $uri := base-uri($doc)
                return json:object((
                    "uri", $uri,
                    if($include = ("content", "all"))
                    then ("content", $doc)
                    else (),
                    if($include = ("collections", "all"))
                    then ("collections", reststore:getDocumentCollections($uri))
                    else (),
                    if($include = ("properties", "all"))
                    then ("properties", reststore:getDocumentProperties($uri))
                    else (),
                    if($include = ("permissions", "all"))
                    then ("permissions", reststore:getDocumentPermissions($uri))
                    else (),
                    if($include = ("quality", "all"))
                    then ("quality", reststore:getDocumentQuality($uri))
                    else (),
                    if($include = ("snippet", "all"))
                    then ("snippet", common:translateSnippet(search:snippet($doc, <cast>{ $query }</cast>/*)))
                    else ()
                ))
            )
        ))
    )
};

declare private function common:translateSnippet(
    $snippet as element(search:snippet)
) as element(json:item)
{
    json:array(
        for $match in $snippet/search:match
        return string-join(
            for $node in $match/node()
            return
                if($node instance of element(search:highlight))
                then concat("<span class='hit'>", string($node), "</span>")
                else string($node)
        , "")
    )
};
