xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" at "/data/lib/json.xqy";


try {
    json:xmlToJSON(json:jsonToXML(xdmp:get-request-field("json")))
}
catch ($e) {
    xdmp:set-response-code(500, string($e//*:message))
}
