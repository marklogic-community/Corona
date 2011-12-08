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

module namespace common="http://marklogic.com/corona/common";
import module namespace json="http://marklogic.com/json" at "json.xqy";
import module namespace dateparser="http://marklogic.com/dateparser" at "date-parser.xqy";
import module namespace config="http://marklogic.com/corona/index-config" at "index-config.xqy";
import module namespace store="http://marklogic.com/corona/store" at "store.xqy";

declare namespace corona="http://marklogic.com/corona";
declare namespace search="http://marklogic.com/appservices/search";
declare namespace sec="http://marklogic.com/xdmp/security";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function common:validateOutputFormat(
    $outputFormat as xs:string
) as xs:boolean
{
    $outputFormat = ("json", "xml")
};

declare function common:error(
    $exceptionCode as xs:string,
    $message as xs:string,
    $outputFormat as xs:string
)
{
    let $isA400 := (
        "corona:DUPLICATE-INDEX-NAME",
        "corona:DUPLICATE-PLACE-ITEM",
        "corona:REQUIRES-BULK-DELETE"
    )
    let $isA500 := (
        "corona:UNSUPPORTED-METHOD",
        "corona:INTERNAL-ERROR"
    )
    let $statusCode :=
        if(starts-with($exceptionCode, "corona:INVALID-") or starts-with($exceptionCode, "corona:MISSING-") or $exceptionCode = $isA400)
        then 400
        else if(ends-with($exceptionCode, "-NOT-FOUND"))
        then 404
        else if($exceptionCode = $isA500)
        then 500
        else 400

    let $set := xdmp:set-response-code($statusCode, $message)
    let $add := xdmp:add-response-header("Date", string(current-dateTime()))
    return
        if($outputFormat = "xml")
        then
            <corona:error>
                <corona:status>{ $statusCode }</corona:status>
                <corona:code>{ $exceptionCode }</corona:code>
                <corona:message>{ $message }</corona:message>
            </corona:error>
        else
            json:document(
                json:object((
                    "error", json:object((
                        "status", $statusCode,
                        "code", $exceptionCode,
                        "message", $message
                    ))
                ))
            )
};

declare function common:errorFromException(
    $exception as element(),
    $outputFormat as xs:string
)
{
    if($exception/*:code = "SEC-ROLEDNE")
    then common:error("corona:INVALID-PERMISSION", concat("The role '", $exception/*:data/*:datum[. != "sec:role-name"], "' does not exist."), $outputFormat)
    else if(starts-with($exception/*:name, "corona:") or starts-with($exception/*:name, "json:") or starts-with($exception/*:name, "path:"))
    then common:error($exception/*:name, $exception/*:message, $outputFormat)
    else (
        xdmp:log($exception),
        common:error("corona:INTERNAL-ERROR", concat($exception/*:message, " (", $exception/*:format-string, ")"), $outputFormat)
    )
};

declare function common:output(
    $item as item()?
) as item()?
{
    common:output($item, ())
};

declare function common:output(
    $item as item()?,
    $binaryHint as xs:string?
) as item()?
{
    let $item :=
        if($item instance of document-node())
        then $item/node()
        else $item
    let $contentType :=
        if($item instance of binary())
        then ($binaryHint, "application/octet-stream")[1]
        else if($item instance of text())
        then "text/plain"
        else if(namespace-uri($item) = "http://marklogic.com/json")
        then "application/json"
        else if($item instance of element())
        then "text/xml"
        else "application/octet-stream"
    let $set := xdmp:set-response-content-type($contentType)
    return
        if(namespace-uri($item) = "http://marklogic.com/json")
        then json:serialize($item)
        else $item
};

declare function common:castFromJSONType(
    $value as xs:anySimpleType,
    $type as xs:string
)
{
    common:castFromJSONType(
        if($type = "boolean")
        then <item boolean="{ $value }"/>
        else <item type="{ $type }">{ $value }</item>
    )
};

declare function common:castFromJSONType(
    $value as element()
)
{
    if($value/@type = "number" and $value castable as xs:double)
    then xs:double($value)

    else if(exists($value/@boolean))
    then $value/@boolean = "true"

    else if($value/@type = "date" and exists($value/@normalized-date))
    then xs:dateTime($value/@normalized-date)
    else if($value/@type = "date")
    then dateparser:parse(string($value))

    else if($value/@type = "xml")
    then $value/*

    else xs:string($value)
};

declare function common:castAs(
    $value as xs:anySimpleType,
    $type as xs:string
)
{
    if($type = "string") then xs:string($value)
    else if($type = "boolean") then xs:boolean($value)
    else if($type = "decimal") then xs:decimal($value)
    else if($type = "float") then xs:float($value)
    else if($type = "double") then xs:double($value)
    else if($type = "duration") then xs:duration($value)
    else if($type = "dateTime") then dateparser:parse($value)
    else if($type = "time") then xs:time($value)
    else if($type = "date") then xs:date($value)
    else if($type = "gYearMonth") then xs:gYearMonth($value)
    else if($type = "gYear") then xs:gYear($value)
    else if($type = "gMonthDay") then xs:gMonthDay($value)
    else if($type = "gDay") then xs:gDay($value)
    else if($type = "gMonth") then xs:gMonth($value)
    else if($type = "hexBinary") then xs:hexBinary($value)
    else if($type = "base64Binary") then xs:base64Binary($value)
    else if($type = "QName") then xs:QName($value)
    else if($type = "integer") then xs:integer($value)
    else if($type = "nonPositiveInteger") then xs:nonPositiveInteger($value)
    else if($type = "negativeInteger") then xs:negativeInteger($value)
    else if($type = "long") then xs:long($value)
    else if($type = "int") then xs:int($value)
    else if($type = "short") then xs:short($value)
    else if($type = "byte") then xs:byte($value)
    else if($type = "nonNegativeInteger") then xs:nonNegativeInteger($value)
    else if($type = "unsignedLong") then xs:unsignedLong($value)
    else if($type = "unsignedInt") then xs:unsignedInt($value)
    else if($type = "unsignedShort") then xs:unsignedShort($value)
    else if($type = "unsignedByte") then xs:unsignedByte($value)
    else if($type = "positiveInteger") then xs:positiveInteger($value)
    else xs:string($value)
};

declare function common:humanOperatorToMathmatical(
    $operator as xs:string?
) as xs:string
{
    if($operator = "eq")
    then "="
    else if($operator = "ne")
    then "!="
    else if($operator = "lt")
    then "<"
    else if($operator = "le")
    then "<="
    else if($operator = "gt")
    then ">"
    else if($operator = "ge")
    then ">="
    else "="
};

declare function common:translateSnippet(
    $snippet as element(search:snippet),
    $outputType as xs:string
) as item()*
{
    let $results :=
        for $match in $snippet/search:match
        return
            string-join(
                for $node in $match/node()
                return
                    if($node instance of element(search:highlight))
                    then concat("<span class='hit'>", string($node), "</span>")
                    else string($node)
            , "")
    return
        if($outputType = "json")
        then json:array($results)
        else $results
};

declare function common:dualStrftime(
    $format as xs:string,
    $date1 as xs:dateTime,
    $date2 as xs:dateTime
) as xs:string
{
    let $firstPass := xdmp:strftime($format, $date1)
    let $changeAtToPercent := replace($firstPass, "([^@])@([^@])", "$1%$2")
    let $secondPass := xdmp:strftime($changeAtToPercent, $date2)
    return replace($secondPass, "@@", "@")
};

declare function common:getContentType(
    $uri as xs:string?,
    $contentType as xs:string?
) as xs:string?
{
    if(exists($contentType))
    then $contentType
    else if(exists($uri))
    then
        let $extension := tokenize($uri, "\.")[last()]
        let $detectedType := xdmp:uri-format($uri)
        return
            if($extension = ("json", "text"))
            then $extension
            else $detectedType
    else error(xs:QName("corona:MISSING-PARAMETER"), "Need to explicitly specify a contentType and/or a URI to auto-detect the content type")
};

declare function common:getOutputFormat(
    $contentType as xs:string*,
    $outputFormat as xs:string?
) as xs:string
{
    if(exists($outputFormat))
    then $outputFormat
    else if($contentType = ("json", "xml"))
    then $contentType
    else if(json:isSupported())
    then "json"
    else "xml"
};

declare function common:processTXID(
    $txid as xs:string,
    $forceHostMatching as xs:boolean
) as map:map
{
    let $map := map:map()
    let $bits := tokenize($txid, ":")
    let $hostID :=
        if($bits[1] castable as xs:unsignedLong)
        then xs:unsignedLong($bits[1])
        else error(xs:QName("corona:INVALID-TRANSACTION"), "Invalid txid: the transaction id contains malformed data")
    let $hostName := try {
        xdmp:host-name($hostID)
    }
    catch ($e) {
        error(xs:QName("corona:INVALID-TRANSACTION"), "Invalid txid: the transaction id contains malformed data")
    }
    let $test :=
        if($forceHostMatching and $hostID != xdmp:host())
        then error(xs:QName("corona:INVALID-TRANSACTION-HOST"), "Cannot process this transaction on this host, must be processed on the host that started the transaction")
        else ()
    let $id :=
        if($bits[2] castable as xs:unsignedLong)
        then xs:unsignedLong($bits[2])
        else error(xs:QName("corona:INVALID-TRANSACTION"), "Invalid txid: the transaction id contains malformed data")
    let $set := map:put($map, "id", $id)
    let $set := map:put($map, "hostName", $hostName)
    let $set := map:put($map, "hostID", $hostID)
    return $map
};

declare function common:transactionsMatch(
    $txid as xs:string?
) as xs:boolean
{
    let $txFunc :=
        try {
            xdmp:function(xs:QName("xdmp:transaction"))
        }
        catch ($e) {
            if(exists($txid))
            then error(xs:QName("corona:INVALID-REQUEST"), "This version of MarkLogic Server does not support transactions.  Upgrade to 5.0 or greater.")
            else ()
        }
    return
        if(exists($txFunc) and exists($txid))
        then map:get(common:processTXID($txid, true()), "id") = xdmp:apply($txFunc)
        else true()
};

declare function common:nsFromQName(
    $item as xs:string
) as xs:string?
{
    if(contains($item, ":"))
    then
        let $ns := namespace-uri-from-QName($item)
        where string-length($ns)
        return $ns
    else ()
};

declare function common:nameFromQName(
    $item as xs:string
) as xs:string?
{
    if(contains($item, ":"))
    then local-name-from-QName($item)
    else ()
};

declare function common:keyToQName(
    $key as xs:string
) as xs:QName
{
    xs:QName(concat("json:", json:escapeNCName($key)))
};

declare function common:xmlOrJSON(
    $string as xs:string?
) as xs:string?
{
    if(empty($string))
    then ()
    else if(starts-with($string, "<"))
    then "xml"
    else "json"
};

declare function common:processPermissionParameter(
    $permissionParams as xs:string*
) as element(sec:permission)*
{
    for $permission in $permissionParams
    let $bits := tokenize($permission, ":")
    let $user := string-join($bits[1 to last() - 1], ":")
    let $access := $bits[last()]
    where exists($user) and $access = ("update", "read", "execute")
    return xdmp:permission($user, $access)
};

declare function common:processPropertiesParameter(
    $propertiesParams as xs:string*
) as element()*
{
    for $property in $propertiesParams
    let $bits := tokenize($property, ":")
    let $name := $bits[1]
    let $value := string-join($bits[2 to last()], ":")
    where exists($name)
    return store:createProperty($name, $value)
};
