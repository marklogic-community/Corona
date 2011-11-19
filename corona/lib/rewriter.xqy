(:
Copyright 2011 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $url := xdmp:get-request-url()
let $result := rest:rewrite(endpoints:options())
return
    if(exists($result))
    then $result
    else if(starts-with($url, "/test") or starts-with($url, "/corona/htools/"))
    then $url
    else concat("/corona/misc/404.xqy?", substring-after(xdmp:get-request-url(), "?"))
