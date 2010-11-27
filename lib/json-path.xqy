module namespace jsonpath="http://marklogic.com/json-path";

import module namespace json="http://marklogic.com/json" at "json.xqy";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function jsonpath:parse(
    $json as xs:string
)
{
    let $tree := json:jsonToXML($json, true())/json
    let $basicPredicate := jsonpath:processStep($tree)
    let $path :=
        if($basicPredicate != "")
        then concat("/json[", $basicPredicate, "]")
        else "/json"

    let $orPredicate := string-join(
            for $item in $tree/orPredicate/item
            return jsonpath:processStep($item)
        , " or ")
    let $path :=
        if($orPredicate != "")
        then concat($path, "[", $orPredicate, "]")
        else $path

    let $andPredicate := string-join(
            for $item in $tree/andPredicate/item
            return jsonpath:processStep($item)
        , " and ")
    let $path :=
        if($andPredicate != "")
        then concat($path, "[", $andPredicate, "]")
        else $path

    let $position := normalize-space($tree/position)
    let $position :=
        if(empty($tree/position) or $position = "1 to last()")
        then ()
        else $position
    return
        if(exists($position))
        then concat("(", $path, ")[", $position, "]")
        else $path
};

declare function jsonpath:processStep(
    $step as element()
) as xs:string
{
    if($step/@type = "number")
    then string($step)
    else if($step/@type = "string")
    then concat("""", string($step), """")
    else if($step/@type = "object")
    then concat(if(local-name($step) = "json" or local-name($step/..) = ("orPredicate", "andPredicate")) then "" else "/", jsonpath:generatePredicate($step))
    else ""
};

declare function jsonpath:generatePredicate(
    $step as element()
) as xs:string
{
    let $key := $step/key[@type = "string"]
    let $innerKey := $step/innerKey[@type = "string"]
    let $key :=
        if(exists($innerKey) and local-name($step) = "json" and empty($key))
        then concat("//", string($innerKey))
        else if(exists($innerKey) and empty($key))
        then concat("/", string($innerKey))
        else $key
    let $value := $step/value
    let $operator := string(($step/comparison, "=")[1])
    return
        if(exists($key) and exists($value))
        then
            if($value/@type = "string")
            then concat(string($key), " ", $operator, " """, string($value), """")
            else if($value/@type = "number")
            then concat(string($key), " ", $operator, " ", string($value))
            else if($value/@type = "array")
            then
                let $bits :=
                    for $item in $value/item
                    where $item/@type = ("string", "number")
                    return jsonpath:processStep($item)
                let $raw := concat(string($key), " = (", string-join($bits,  ", "), ")")
                return
                    if($operator = "!=")
                    then concat("not(", $raw, ")")
                    else $raw
            else if($value/@type = "object")
            then
                if(empty($value//value) and local-name($value/..) = "json")
                then concat("exists(", $key, jsonpath:processStep($value), ")")
                else concat($key, jsonpath:processStep($value))
            else ""
        else if(exists($key) and empty($value) and local-name($key/..) = "json")
        then concat("exists(", $key, ")")
        else if(exists($key) and empty($value))
        then string($key)
        else ""
};
