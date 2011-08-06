import module namespace dateparser="http://marklogic.com/dateparser" at "/data/lib/date-parser.xqy";

dateparser:parse(xdmp:get-request-field("date"))
