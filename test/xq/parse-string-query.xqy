import module namespace stringquery="http://marklogic.com/corona/string-query" at "/corona/lib/string-query.xqy";

declare option xdmp:mapping "false";

try {
    normalize-space(replace(xdmp:quote(<foo>{ stringquery:parse(xdmp:get-request-field("stringQuery"), (), false()) }</foo>/*), "\n", ""))
}
catch ($e) {
    xdmp:log($e),
    string($e/*:message)
}
