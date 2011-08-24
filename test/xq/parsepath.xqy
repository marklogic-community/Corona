import module namespace path="http://marklogic.com/mljson/path-parser" at "/corona/lib/path-parser.xqy";

declare option xdmp:mapping "false";

try {
    path:parse(xdmp:get-request-field("path"), xdmp:get-request-field("type"))
}
catch ($e) {
    string($e/*:message)
}
