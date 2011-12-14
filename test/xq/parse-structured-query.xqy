import module namespace structquery="http://marklogic.com/corona/structured-query" at "/corona/lib/structured-query.xqy";

declare option xdmp:mapping "false";

try {
    normalize-space(replace(xdmp:quote(<foo>{ structquery:getCTS(structquery:getParseTree(xdmp:get-request-field("q")), xdmp:get-request-field("ignoreRange"), false()) }</foo>/*), "\n", ""))
}
catch ($e) {
    xdmp:log($e),
    string($e/*:message)
}
