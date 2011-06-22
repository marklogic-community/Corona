xquery version "1.0-ml";

module namespace endpoints="http://marklogic.com/mljson/endpoints";

import module namespace rest="http://marklogic.com/appservices/rest" at "/data/lib/rest/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $endpoints:ENDPOINTS as element(rest:options) :=
<options xmlns="http://marklogic.com/appservices/rest">
    <!-- Manage documents in the database -->
    <request uri="^/data/store/(.+)$" endpoint="/data/jsonstore.xqy" user-params="allow">
        <uri-param name="uri" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="POST"/>
        <http method="PUT"/>
        <http method="DELETE"/>
    </request>

    <!-- Querying the database -->
    <request uri="^/data/query(/)?$" endpoint="/data/jsonquery.xqy">
        <param name="q" required="true"/>
        <http method="GET"/>
        <http method="POST"/>
    </request>

    <!-- Info request -->
    <request uri="^/data/info(/)?$" endpoint="/data/info.xqy" user-params="ignore"/>
</options>;

declare function endpoints:options(
) as element(rest:options)
{
    $ENDPOINTS
};

declare function endpoints:request(
    $module as xs:string
) as element(rest:request)?
{
    ($ENDPOINTS/rest:request[@endpoint = $module])[1]
};
