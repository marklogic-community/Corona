module namespace jsonpath="http://marklogic.com/json-path";

import module namespace json="http://marklogic.com/json" at "json.xqy";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function jsonpath:parse(
    $json as xs:string
)
{
    let $tree := json:jsonToXML($json, true())
    return concat("/json", jsonpath:processStep($tree/*))
};

declare function jsonpath:processStep(
    $step as element()
) as xs:string
{
    let $key := $step/key[@type = "string"]
    let $value := $step/value
    return string-join((
        if(exists($key))
        then concat("/", string($key))
        else ()
        ,
        if(exists($key) and exists($value))
        then jsonpath:generatePredicate($step)
        else ()
    ), "")
};

declare function jsonpath:generatePredicate(
    $step as element()
) as xs:string
{
    let $value := $step/value
    let $comparison := (string($step/comparison), "=")[1]
    (:
    let $simpleOperator :=
        if($comparison = ("contains", "array contains"))
        then "="
        else $comparison
    :)
    return concat("[", jsonpath:predicateValue($value, $comparison), "]")
};

declare function jsonpath:predicateValue(
    $value as element(),
    $operator as xs:string
) as xs:string
{
    if($value/@type = "string")
    then concat(". ", $operator, " """, string($value), """")
    else if($value/@type = "array")
    then string-join(
        for $item in $value/item
        return jsonpath:predicateValue($item, $operator)
        ,  if($operator = "!=") then " and " else " or ")
    else ""
};

