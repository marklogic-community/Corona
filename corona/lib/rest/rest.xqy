xquery version "1.0-ml";

module namespace rest="http://marklogic.com/appservices/rest";

import module namespace rest-impl="http://marklogic.com/appservices/rest-impl"
    at "rest-impl.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $rest:UNACCEPTABLETYPE  := xs:QName("rest:UNACCEPTABLETYPE");
declare variable $rest:UNSUPPORTEDPARAM  := xs:QName("rest:UNSUPPORTEDPARAM");
declare variable $rest:INVALIDTYPE       := xs:QName("rest:INVALIDTYPE");
declare variable $rest:INCORRECTURI      := xs:QName("rest:INCORRECTURI");
declare variable $rest:UNSUPPORTEDMETHOD := xs:QName("rest:UNSUPPORTEDMETHOD");
declare variable $rest:INVALIDPARAM      := xs:QName("rest:INVALIDPARAM");
declare variable $rest:REPEATEDPARAM     := xs:QName("rest:REPEATEDPARAM");
declare variable $rest:REQUIREDPARAM     := xs:QName("rest:REQUIREDPARAM");
declare variable $rest:INVALIDCONDITION  := xs:QName("rest:INVALIDCONDITION");
declare variable $rest:FAILEDCONDITION   := xs:QName("rest:FAILEDCONDITION");

(: ====================================================================== :)

declare function rest:rewrite(
  $options as element(rest:options)
) as xs:string?
{
  let $reqenv := rest:request-environment()
  return
    rest-impl:rewrite($options/rest:request, rest:request-environment())
};

declare function rest:rewrite(
  $options as element(rest:options),
  $uri as xs:string)
as xs:string?
{
  let $reqenv := rest:request-environment()
  let $_ := map:put($reqenv, "uri", $uri)
  return
    rest-impl:rewrite($options/rest:request, $reqenv)
};

declare function rest:rewrite(
  $requests as element(rest:request)*,
  $uri as xs:string,
  $method as xs:string,
  $accept-headers as xs:string*,
  $user-params as map:map)
as xs:string?
{
  let $reqenv := rest:request-environment()
  let $_ := map:put($reqenv, "uri", $uri)
  let $_ := map:put($reqenv, "method", $method)
  let $_ := map:put($reqenv, "accept", $accept-headers)
  let $_ := map:put($reqenv, "params", $user-params)
  return
   rest-impl:rewrite($requests, $reqenv)
};

declare function rest:request-environment()
as map:map
{
  let $params := map:map()
  let $_ := for $name in xdmp:get-request-field-names()
            let $values
              := for $value in xdmp:get-request-field($name)
                 return
                   xdmp:url-decode($value)
            return
              map:put($params, xdmp:url-decode($name), $values)

  let $reqenv := map:map()
  let $_       := map:put($reqenv, "uri", xdmp:get-request-url())
  let $_       := map:put($reqenv, "method", xdmp:get-request-method())
  let $_       := map:put($reqenv, "accept", xdmp:get-request-header("Accept"))
  let $_       := map:put($reqenv, "user-agent", xdmp:get-request-header("User-Agent"))
  let $_       := map:put($reqenv, "params", $params)
  return
    $reqenv
};

(: ====================================================================== :)

declare function rest:matching-request(
  $options as element(rest:options))
as element(rest:request)?
{
  let $reqenv := rest:request-environment()
  return
    rest-impl:matching-request($options/rest:request, $reqenv)
};

declare function rest:matching-request(
  $options as element(rest:options),
  $uri as xs:string,
  $method as xs:string,
  $accept-headers as xs:string*,
  $user-params as map:map)
as element(rest:request)?
{
  let $reqenv := rest:request-environment()
  let $_ := map:put($reqenv, "uri", $uri)
  let $_ := map:put($reqenv, "method", $method)
  let $_ := map:put($reqenv, "accept", $accept-headers)
  let $_ := map:put($reqenv, "params", $user-params)
  return
    rest-impl:matching-request($options/rest:request, $reqenv)
};

declare function rest:process-request(
  $request as element(rest:request))
as map:map
{
  let $reqenv := rest:request-environment()
  return
    rest-impl:process-request($request, $reqenv)
};

declare function rest:check-options(
  $options as element(rest:options))
as element(rest:report)?
{
  rest-impl:check-options($options)
};

declare function rest:check-request(
  $options as element(rest:request))
as element(rest:report)?
{
  rest-impl:check-request($options)
};

declare function rest:test-request-method(
  $request as element(rest:request))
as empty-sequence()
{
  let $method := xdmp:get-request-method()
  let $test := rest-impl:method-matches($request, $method, true())
  return
    ()
};

declare function rest:test-conditions(
  $request as element(rest:request))
as empty-sequence()
{
  let $reqenv := rest:request-environment()
  let $test := rest-impl:conditions-match($request, $reqenv, true())
  return
    ()
};

declare function rest:get-acceptable-types(
  $types as xs:string*)
as xs:string*
{
  rest-impl:get-return-types($types, xdmp:get-request-header("Accept"))
};

declare function rest:get-raw-query-params()
as map:map
{
  let $params := map:map()
  let $_ := for $name in xdmp:get-request-field-names()
            let $values := xdmp:get-request-field($name)
            return
              map:put($params, $name, $values)
  return
    $params
};

declare function rest:report-error(
  $error as element())
as element()
{
  rest-impl:report-error($error)
};


