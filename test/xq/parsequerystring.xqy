import module namespace parser="http://marklogic.com/corona/query-parser" at "/corona/lib/query-parser.xqy";

declare option xdmp:mapping "false";

try {
    normalize-space(replace(xdmp:quote(<foo>{ parser:parse(xdmp:get-request-field("q")) }</foo>/*), "\n", ""))
}
catch ($e) {
    xdmp:log($e),
    string($e/*:message)
}
