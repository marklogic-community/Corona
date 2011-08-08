import module namespace customquery="http://marklogic.com/mljson/custom-query" at "/data/lib/custom-query.xqy";

declare option xdmp:mapping "false";

try {
    normalize-space(replace(xdmp:quote(<foo>{ customquery:getCTS(xdmp:get-request-field("q"), xdmp:get-request-field("ignoreRange")) }</foo>/*), "\n", ""))
}
catch ($e) {
    xdmp:log($e),
    string($e/*:message)
}
