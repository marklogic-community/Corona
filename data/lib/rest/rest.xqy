xquery version "1.0-ml";

module namespace rest="http://marklogic.com/appservices/rest";

import module namespace rest-impl="http://marklogic.com/appservices/rest-impl"
    at "rest-impl.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

(: These are the QNames of errors that may be thrown by functions in this module; note that
   the $rest:OPTIONSMETHOD is handled specially by rest:format-error()
 :)
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
  $options as element(rest:options))
as xs:string?
{
  let $uri := xdmp:get-request-url()
  return
    rest:rewrite($options, $uri)
};

declare function rest:rewrite(
  $options as element(rest:options),
  $uri as xs:string)
as xs:string?
{
  let $method := xdmp:get-request-method()
  let $accept-headers := xdmp:get-request-header("Accept")
  let $user-params := rest-impl:uri-parameters($uri)
  return
    rest:rewrite($options/rest:request, $uri, $method, $accept-headers, $user-params)
};

declare function rest:rewrite(
  $requests as element(rest:request)*,
  $uri as xs:string,
  $method as xs:string,
  $accept-headers as xs:string*,
  $user-params as map:map)
as xs:string?
{
    rest-impl:rewrite($requests, $uri, $method, $accept-headers, $user-params)
};

declare function rest:matching-request(
  $options as element(rest:options))
as element(rest:request)?
{
  let $uri     := xdmp:get-request-url()
  let $method  := xdmp:get-request-method()
  let $accept  := xdmp:get-request-header("Accept")
  let $params  := rest:get-raw-query-params()
  return
    rest:matching-request($options, $uri, $method, $accept, $params)
};

declare function rest:matching-request(
  $options as element(rest:options),
  $uri as xs:string,
  $method as xs:string,
  $accept-headers as xs:string*,
  $user-params as map:map)
as element(rest:request)?
{
  rest-impl:matching-request($options/rest:request, $uri, $method, $accept-headers, $user-params)
};

declare function rest:process-request(
  $request as element(rest:request))
as map:map
{
  rest-impl:process-request($request)
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
  let $uri := xdmp:get-request-url()
  let $method := xdmp:get-request-method()
  let $test := rest-impl:conditions-match($request, $uri, $method, true())
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
  let $uri := xdmp:get-request-url()
  return
    rest-impl:uri-parameters($uri)
};

declare function rest:report-error(
  $error as element())
as element()
{
  rest-impl:report-error($error)
};

