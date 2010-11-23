xquery version "1.0-ml";

import module namespace json="http://marklogic.com/json" at "lib/json.xqy";
import module namespace stox = "http://marklogic.com/commons/query-xml" at "lib/query-xml.xqy";

let $keys := xdmp:get-request-field-names()

let $ctsQuery :=
    for $key in $keys
    return cts:or-query(
        for $param in xdmp:get-request-field($key)
        let $values := stox:searchToXml($param, (), (), (), ())
        where exists($param) and not($param = "")
        return cts:and-query(
            for $value in $values/term
            return cts:element-word-query(xs:QName($key), string($value))
        )
    )

let $results := cts:search(/json, cts:and-query($ctsQuery))[1 to 25]

return json:xmlToJson(<json type="array">{
    for $result in $results
    return <item type="object">{ $result/* }</item>
}</json>)
