import module namespace path="http://marklogic.com/mljson/path-parser" at "/data/lib/path-parser.xqy";

declare option xdmp:mapping "false";

try {
    path:parse(xdmp:get-request-field("path"))
}
catch ($e) {
    string($e/*:message)
}
