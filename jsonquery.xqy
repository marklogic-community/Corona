xquery version "1.0-ml";

import module namespace jsonpath="http://marklogic.com/json-path" at "lib/json-path.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

let $requestMethod := xdmp:get-request-method()
let $query := string(xdmp:get-request-field("q", "{}")[1])
let $query :=
    if(string-length(normalize-space($query)) = 0)
    then "{}"
    else $query

return
    if($requestMethod = ("GET", "POST"))
    then
        let $docs := jsonpath:execute($query)
        let $jsonDocs := for $doc in $docs return json:xmlToJSON($doc)
        return concat("{""count"":", count($jsonDocs) , ", ""results"":[", string-join($jsonDocs, ","), "]}")
    else ()
