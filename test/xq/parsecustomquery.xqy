import module namespace customquery="http://marklogic.com/corona/custom-query" at "/corona/lib/custom-query.xqy";

declare option xdmp:mapping "false";

try {
    normalize-space(replace(xdmp:quote(<foo>{ customquery:getCTS(customquery:getParseTree(xdmp:get-request-field("q")), xdmp:get-request-field("ignoreRange")) }</foo>/*), "\n", ""))
}
catch ($e) {
    xdmp:log($e),
    string($e/*:message)
}
