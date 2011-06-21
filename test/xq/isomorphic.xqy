xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" at "/lib/json.xqy";

try {
    let $json := xdmp:get-request-field("json")
    let $transformed := json:xmlToJSON(json:jsonToXML($json))
    let $valid := $json = $transformed
    let $log :=
        if($valid)
        then ()
        else xdmp:log(fn:concat("Got: ", $transformed, " Expected: ", $json))
    return $valid
}
catch ($e) {
    fn:concat("Logged Exception: ", $e//*:message),
    xdmp:log(fn:concat("Exception: ", xdmp:quote($e), " Expected: ", xdmp:get-request-field("json")))
}
