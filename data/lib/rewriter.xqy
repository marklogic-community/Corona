xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/data/lib/rest/rest.xqy";

import module namespace endpoints="http://marklogic.com/mljson/endpoints" at "/config/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $uri := xdmp:get-request-url()
let $result := rest:rewrite(endpoints:options())
return
    if(empty($result))
    then $uri
    else $result
