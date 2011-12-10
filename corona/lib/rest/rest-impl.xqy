xquery version "1.0-ml";

module namespace rest-impl="http://marklogic.com/appservices/rest-impl";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace rest="http://marklogic.com/appservices/rest";

declare option xdmp:mapping "false";

(: The following known types may be listed in the @as attribute of a param :)
declare variable $rest-impl:KNOWN_TYPES
  := ("NCName", "NMTOKEN", "NMTOKENS", "Name", "QName", "anyURI",
      "base64Binary", "boolean", "byte", "date", "dateTime", "decimal",
      "double", "duration", "float", "gDay", "gMonth", "gMonthDay", "gYear",
      "gYearMonth", "hexBinary", "int", "integer", "language", "long",
      "negativeInteger", "nonNegativeInteger", "nonPositiveInteger",
      "normalizedString", "positiveInteger", "short", "string", "time",
      "token", "unsignedByte", "unsignedInt", "unsignedLong",
      "unsignedShort");

(: These are the QNames of errors that may be thrown by functions in this module. :)
declare variable $rest-impl:UNACCEPTABLETYPE  := xs:QName("rest:UNACCEPTABLETYPE");
declare variable $rest-impl:UNSUPPORTEDPARAM  := xs:QName("rest:UNSUPPORTEDPARAM");
declare variable $rest-impl:INVALIDTYPE       := xs:QName("rest:INVALIDTYPE");
declare variable $rest-impl:INCORRECTURI      := xs:QName("rest:INCORRECTURI");
declare variable $rest-impl:UNSUPPORTEDMETHOD := xs:QName("rest:UNSUPPORTEDMETHOD");
declare variable $rest-impl:INVALIDPARAM      := xs:QName("rest:INVALIDPARAM");
declare variable $rest-impl:REPEATEDPARAM     := xs:QName("rest:REPEATEDPARAM");
declare variable $rest-impl:REQUIREDPARAM     := xs:QName("rest:REQUIREDPARAM");
declare variable $rest-impl:INVALIDCONDITION  := xs:QName("rest:INVALIDCONDITION");
declare variable $rest-impl:FAILEDCONDITION   := xs:QName("rest:FAILEDCONDITION");

(: ====================================================================== :)
(: These functions are a bit of an odd hack; in the versions of this
   library shipped with MarkLogic Server, we actually import a debug
   module that contains the logging function. Here we just put in a
   local function for convenience.
:)

declare variable $rest-impl:DEBUG as xs:boolean := false();

declare function rest-impl:log($msgs as item()*) as empty-sequence() {
  if ($rest-impl:DEBUG)
  then for $msg in $msgs return xdmp:log($msg)
  else ()
};

declare function rest-impl:check-reqenv(
  $reqenv as map:map
) as empty-sequence()
{
  ()
};

declare function rest-impl:dump-reqenv(
  $reqenv as map:map
) as empty-sequence()
{
  let $uri    := map:get($reqenv, "uri")
  let $method := map:get($reqenv, "method")
  let $accept := map:get($reqenv, "accept")
  let $params := map:get($reqenv, "params")
  return
    (rest-impl:log("Request environment:"),
     rest-impl:log(concat($method, " ", $uri)),
     rest-impl:log(concat("ACCEPT ", $accept)),
     rest-impl:log("PARAMS:"),
     for $name in map:keys($params)
     return
       rest-impl:log(concat("  ", $name, ": (", string-join(map:get($params, $name), ", "), ")")),
     rest-impl:log(""))
};

(:
declare function rest-impl:dump-map(
  $map as map:map,
  $title as xs:string?
) as empty-sequence()
{
  (xdmp:log("<map>"),
   if (empty($title)) then () else xdmp:log($title),
   for $name in map:keys($map)
   return
   xdmp:log(concat($name, "=(", string-join(map:get($map, $name), ", "), ")")),
   xdmp:log("</map>"))
};
:)

(: ====================================================================== :)

declare function rest-impl:rewrite(
  $requests as element(rest:request)*,
  $reqenv as map:map
) as xs:string?
{
  let $trace     := rest-impl:dump-reqenv($reqenv)
  let $matches   := rest-impl:matching-request($requests, $reqenv)
  let $request   := $matches[1]
  let $params    := $matches[2]
  let $defparams := $matches[3]
  let $endpoint  := $request/@endpoint/string()
  let $uri       := map:get($reqenv, "uri")

  (: Ok. Now the tricky bit is that we need to add the uri-param parameters to the
     rewritten request URI without disturbing the actual parameters that might have
     been passed there. But, there's a wrinkle: if there's a parameter that
     is *both* a URI param and is passed on the URI, we need to make sure that we
     don't duplicate it. And another wrinkle: we want to make defaulted parameters
     explicit in order to make the endpoint's job easier.
  :)

  let $uriparams
    := for $name in $request/rest:uri-param/@name
       for $value in map:get($params, $name)
       return
         concat($name, "=", $value)

  let $reqparams
    := for $param in tokenize(if (contains($uri, "?")) then substring-after($uri, "?") else "", "&amp;")
       where not($param = $uriparams)
       return
         $param

  let $addparams
    := if (empty($defparams))
       then ()
       else
         for $name in map:keys($defparams)
         for $value in map:get($defparams, $name)
         return
           concat($name, "=", $value)

  let $eparam   := string-join(($reqparams, $uriparams, $addparams), "&amp;")
  let $sep      := if (contains($endpoint,"?")) then "&amp;" else "?"
  let $result
    := if (empty($endpoint))
       then
         ()
       else
         concat($endpoint,
                if ($eparam = "") then "" else concat($sep, $eparam))
  let $trace := rest-impl:log(concat($uri, " => ", $result))
  return
    $result
};

declare function rest-impl:matching-request(
  $requests as element(rest:request)*,
  $reqenv as map:map
) (: returns a sequence of (req:request, map:map, map:map) or the empty sequence :)
{
  if (empty($requests))
  then
    rest-impl:log("Out of requests: rewrite returns empty sequence")
  else
    let $trace   := rest-impl:log(("==> Matches request:", $requests[1]))
    let $matches := rest-impl:matches($requests[1], $reqenv, false(), false())
    let $trace   := rest-impl:log((concat("==> ",exists($matches)),""))
    return
      if (exists($matches))
      then
        ($requests[1], $matches)
      else
        rest-impl:matching-request($requests[position()>1], $reqenv)
};

(: ====================================================================== :)

declare private function rest-impl:matches(
  $request as element(rest:request),
  $reqenv as map:map,
  $raise-errors as xs:boolean,
  $process-request as xs:boolean
) as map:map*
{
  let $uri    := map:get($reqenv, "uri")
  let $uri    := if (contains($uri,"?")) then substring-before($uri, "?") else $uri
  let $method := map:get($reqenv, "method")
  return
    if (($process-request or rest-impl:uri-matches($request, $uri, $raise-errors))
        and rest-impl:method-matches($request, $method, $raise-errors))
    then
      let $uri-ok    := $process-request or rest-impl:uri-params-ok($request, $reqenv, $raise-errors)
      let $plist     := rest-impl:params($request, $reqenv, $process-request)
      let $params    := $plist[1]
      let $defparams := $plist[2]
      let $match-ok  := rest-impl:params-match($request, $reqenv, $params, $raise-errors)
      let $cond-ok   := rest-impl:conditions-match($request, $reqenv, $raise-errors)
      return
        if ($uri-ok and $match-ok and $cond-ok)
        then
          ($params, $defparams)
        else
          ()
    else
      ()
};

declare private function rest-impl:uri-matches(
  $request as element(rest:request),
  $uri as xs:string,
  $raise-errors as xs:boolean)
as xs:boolean
{
  if ($request/@uri and not(matches($uri, $request/@uri)))
  then
    rest-impl:no-match($raise-errors, $rest-impl:INCORRECTURI, concat($uri, " does not match ", $request/@uri))
  else
    true()
};

declare function rest-impl:method-matches(
  $request as element(rest:request),
  $method as xs:string,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $http := rest-impl:http-method($request, $method)
  return
    if (exists($http) or (empty($request/rest:http) and $method="GET"))
    then
      true()
    else
      (rest-impl:log(concat("METHOD ", $method, " does not match")),
       rest-impl:no-match($raise-errors, $rest-impl:UNSUPPORTEDMETHOD, $method))
};

declare private function rest-impl:http(
  $request as element(rest:request),
  $reqenv as map:map
) as element(rest:http)*
{
  let $method := map:get($reqenv, "method")
  return
    rest-impl:http-method($request, $method)
};

declare private function rest-impl:http-method(
  $request as element(rest:request),
  $method as xs:string
) as element(rest:http)*
{
  for $http in $request/rest:http
  let $methods := tokenize($http/@method, '\s+')
  where $method = $methods
  return
    $http
};

declare private function rest-impl:uri-params-ok(
  $req as element(rest:request),
  $reqenv as map:map,
  $raise-errors as xs:boolean
) as xs:boolean
{
  let $user-params := map:get($reqenv, "params")
  let $upset := string((rest-impl:http($req,$reqenv)/@user-params,
                        $req/@user-params,
                        $req/parent::rest:options/@user-params)[1])
  let $errors
    := if ($upset = "allow-dups")
       then
         ()
       else
         for $param in ($req/rest:uri-param, rest-impl:http($req,$reqenv)/rest:uri-param)
         where exists(map:get($user-params, $param/@name))
         return
           rest-impl:no-match($raise-errors, $rest-impl:INVALIDPARAM, $param/@name)
  return
    empty($errors)
};

declare private function rest-impl:copy-map(
  $map as map:map
) as map:map
{
  let $newmap := map:map()
  let $_      := for $key in map:keys($map)
                 return
                   map:put($newmap, $key, map:get($map, $key))
  return
    $newmap
};

declare function rest-impl:params(
  $request as element(rest:request),
  $reqenv as map:map,
  $process-request as xs:boolean
) as map:map+
{
  let $uri    := map:get($reqenv, "uri")
  let $uri    := if (contains($uri,"?")) then substring-before($uri, "?") else $uri
  let $user-params := rest-impl:copy-map(map:get($reqenv, "params"))

  (: Make sure we look at all params, not just top-level ones. :)
  let $allparam := ($request/rest:param, rest-impl:http($request, $reqenv)/rest:param)

  let $upset   := string((rest-impl:http($request,$reqenv)/@user-params,
                          $request/@user-params,
                          $request/parent::rest:options/@user-params)[1])

  let $map := map:map()
  let $defmap := map:map()

  (: Add the uri-param parameters to the map. If we're processing a request, then the
     rewriter will already have put the uri-params in the user-params during the
     rewrite, so just copy them over
  :)
  let $_   := for $param in $request/rest:uri-param
              return
                if ($process-request)
                then (map:put($map, $param/@name, map:get($user-params, $param/@name)),
                      map:delete($user-params, $param/@name))
                else map:put($map, $param/@name, replace($uri, $request/@uri, $param))

  (: Add the param parameters to the map :)
  let $_   := for $param in $allparam
              let $name    := string($param/@name)
              let $values  := if ($param/@from)
                              then map:get($user-params, $param/@from)
                              else
                                let $uvalue := map:get($user-params, $name)
                                return
                                  if (empty($uvalue))
                                  then
                                    if ($param/@default)
                                    then
                                      (map:put($defmap, $name, string($param/@default)),
                                       string($param/@default))
                                    else
                                      ()
                                  else $uvalue

              let $value
                := for $value in $values
                   let $match := if ($param/@match) then matches($value, $param/@match) else true()
                   return
                     if ($match)
                     then
                       if ($param/@match)
                       then replace($value, $param/@match, $param)
                       else $value
                     else
                       ()
              return
                if (empty($value))
                then ()
                else map:put($map, $name, $value)

  (: Add extra parameters to the map :)
  let $from := distinct-values($allparam/@from)

  let $uparams := if ($upset = "ignore")
                  then
                    ()
                  else
                    for $name in map:keys($user-params)
                    where $upset = "allow-dups"
                          or (not($name = $from) and empty($allparam[@name = $name]))
                    return $name

  let $_   := for $name in $uparams
              let $aname  := rest-impl:param-alias($allparam, $name)
              let $values := (if ($upset = "allow-dups") then map:get($map, $name) else (),
                              map:get($user-params, $name))
              return
                map:put($map, $aname, $values)
  return
    ($map,$defmap)
};

declare private function rest-impl:param-alias(
  $allparam as element(rest:param)*,
  $name as xs:string
) as xs:string
{
  let $alias
    := for $param in $allparam[@alias]
       let $aliases := tokenize($param/@alias, "\s*\|\s*")
       where $name = $aliases
       return
         $param/@name/string()
  return
    if (empty($alias))
    then
      $name
    else
      $alias
};

declare private function rest-impl:params-match(
  $request as element(rest:request),
  $reqenv as map:map,
  $params as map:map,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $uri-params  := $request/rest:uri-param
  let $req-params  := ($request/rest:param, rest-impl:http($request,$reqenv)/rest:param)
  let $user-params := string((rest-impl:http($request,$reqenv)/@user-params,
                              $request/@user-params,
                              $request/parent::rest:options/@user-params)[1])

  let $errors
    := (
         (: check for missing required params :)
         for $param in $req-params
         where ($param/@required="true")
         return
           if (map:get($params, $param/@name))
           then ()
           else
             rest-impl:no-match($raise-errors, $rest-impl:REQUIREDPARAM, $param/@name),

         (: check for extra params :)
         if ($user-params = "" or $user-params = "forbid")
         then
           for $name in map:keys($params)
           where not($uri-params[@name=$name]) and not($req-params[@name=$name])
           return
             rest-impl:no-match($raise-errors, $rest-impl:UNSUPPORTEDPARAM, $name)
         else
           (),

         (: check for incorrectly repeated params :)
         for $param in $req-params
         let $name := $param/@name
         where ((empty($param/@repeatable) or $param/@repeatable="false")
                and (count(map:get($params, $name)) > 1))
         return
           rest-impl:no-match($raise-errors, $rest-impl:REPEATEDPARAM, $name),

         (: check for param types :)
         for $param in ($uri-params[@as]|$req-params[@as]
                        |$uri-params[@values]|$req-params[@values])
         let $as     := if ($param/@as) then normalize-space($param/@as) else "string"
         let $legal-values := if ($param/@values) then string($param/@values) else ()
         let $values  := map:get($params, $param/@name)
         return
           for $value in $values
           where not(rest-impl:valid-atomic-type($value, $as, $legal-values))
           return
             rest-impl:no-match($raise-errors, $rest-impl:INVALIDTYPE,
                                concat($value, " as ",
                                if (empty($legal-values))
                                then $as
                                else concat("(", $legal-values, ")")))
       )
  return
    empty($errors)
};

(: ====================================================================== :)

declare function rest-impl:conditions(
  $elem as element()*)
as element()*
{
  $elem[not(self::rest:param)
        and not(self::rest:uri-param)
        and not(self::rest:http)]
};

(: ====================================================================== :)

(: This functions determines which if any of the specified return types are
   acceptable to the caller. This does handle the quality parameter, but
   is still very crude in terms of handling of media-range vs. accept params.
 :)

declare function rest-impl:types-match(
  $types as xs:string*,
  $accept as xs:string*,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $mtypes := rest-impl:get-return-types($types, $accept)
  return
  if (empty($mtypes))
  then
    rest-impl:no-match($raise-errors, $rest-impl:UNACCEPTABLETYPE,
                       string-join(for $type in $mtypes return concat("'",$type,"'"), ", "))
  else
    true()
};

declare function rest-impl:get-return-types(
  $types as xs:string*,
  $accept-headers as xs:string*)
as xs:string*
{
  let $accept-map := map:map()
  let $match-map := map:map()
  let $accept :=
    for $typespec in $accept-headers
    let $toks := tokenize($typespec, ",")
    for $tok in $toks
    let $tok := normalize-space($tok)
    return
      if (contains($tok, ";"))
      then
        let $split := tokenize($tok, ";")
        let $weight-map := map:map()
        let $key := normalize-space($split[1])
        let $params
          := for $param in $split[2 to count($split)]
             let $param := normalize-space($param)
             return
               if (starts-with($param,"q="))
               then map:put($weight-map,$key,xs:double(substring-after($param,"q=")))
               else (map:put($weight-map,$key,1),$param)
        return
          if ($params)
          then
            let $ext-key := string-join(($key,$params),";")
            return (map:put($accept-map,$ext-key,map:get($weight-map,$key)),$ext-key)
          else (map:put($accept-map,$key,map:get($weight-map,$key)),$key)
      else
        (map:put($accept-map,$tok,1),$tok)
  let $exact-match
    := for $rtype in $types
       return
         if ($rtype = $accept)
         then (map:put($match-map,$rtype,map:get($accept-map,$rtype)))
         else ()
  let $wildcard
    := if (empty($exact-match))
       then
         for $rtype in $types
         for $atype in $accept
         return
           if (($atype eq "*/*")
               or (substring-after($atype, "/") eq "*"
               and substring-before($rtype, "/") eq substring-before($atype, "/")))
           then
             let $existing := map:get($match-map,$rtype)
             return
               if (empty($existing) or $existing lt map:get($accept-map,$atype))
               then (map:put($match-map,$rtype,map:get($accept-map,$atype)),$rtype)
               else ()
           else ()
       else ()
(:
  let $_ := for $i in map:keys($accept-map)
            return rest-impl:log(concat("   accept: ", $i, ": ", map:get($accept-map,$i)))
  let $_ := for $i in map:keys($match-map)
            return rest-impl:log(concat("   match : ", $i, ": ", map:get($match-map,$i)))
:)

  (: Ok. Now where are we?

     At this point, we've populated $match-map with all the matches
     (either exact or wildcard). The keys of the map are the types,
     the values are the q= values. So if we return the keys in
     value/descending order, we can be sure that all q=1.0 values will
     precede all q=0.9 values. But the trouble is, this is a *map* so
     all the keys that have the same q= value will be returned in an
     indeterminate order. What to do. What to do.

     It's tricky because we want to sort in descending order by q=
     value and in ascending order by the ordinal position of the type
     in the original list.

     Unless I'm overlooking something clever, I think the answer is
     ... brute force. Grab each group of values with the same q= value
     (in descending order) and select the members of that group in
     ascending order by position.
  :)

  let $all-q-values := distinct-values(for $i in map:keys($match-map)
                                       return map:get($match-map, $i))
  let $q-values     := for $value in $all-q-values order by $value descending return $value

  return
    if (empty($accept)) then $types
    else
      for $q in $q-values
      let $matching-types := for $i in map:keys($match-map)
                             where map:get($match-map, $i) = $q
                             return
                               $i
      for $type in $types
      where $type = $matching-types
      return
        $type
};

declare function rest-impl:accept(
    $request as element(rest:request),
    $reqenv as map:map,
    $accept-headers as xs:string*)
as empty-sequence()
{
  let $types := ($request/rest:accept, rest-impl:http($request,$reqenv)/rest:accept)/string()
  return
    if (exists($types) and empty(rest-impl:get-return-types($types,$accept-headers)))
    then rest-impl:no-match(true(), $rest-impl:UNACCEPTABLETYPE,
                            string-join(for $type in $types return concat("'",$type,"'"), ", "))
    else ()
};

(: ====================================================================== :)

declare private function rest-impl:no-match(
  $raise-errors as xs:boolean,
  $error as xs:QName,
  $message as xs:string)
as xs:boolean
{
  let $trace := rest-impl:log(concat("==> no-match; error: ", $error, "; msg: ", $message))
  return
    if ($raise-errors)
    then
      error($error, concat("REST-", local-name-from-QName($error), " ", $message))
    else
      false()
};

(: ====================================================================== :)


(: This private function validates a single rest-impl:param. :)
declare private function rest-impl:valid-atomic-type(
  $value as xs:string,
  $type as xs:string?,
  $acceptable-values as xs:string?)
as xs:boolean
{
  try {
    let $v := rest-impl:as-atomic-type($value, $type, $acceptable-values)
    return
      true()
  } catch ($e) {
    false()
  }
};

(: This private function validates a single rest-impl:param. :)
declare private function rest-impl:as-atomic-type(
  $value as xs:string,
  $type as xs:string?,
  $acceptable-values as xs:string?)
as xs:anyAtomicType
{
  let $legal-values
    := for $v in tokenize($acceptable-values, "\s*\|\s*") return normalize-space($v)
  let $strval
    := if (empty($acceptable-values))
       then
         $value
       else
         if ($value = $legal-values)
         then
           $value
         else
           error($rest-impl:UNACCEPTABLETYPE, concat($value, " not ", $acceptable-values))

  let $errchk
    := if (contains($type, "|"))
       then
         rest-impl:log(concat("Attempt to validate '", $value, "' as '", $type, "'. ",
                              "'@as' contains '|'; perhaps you meant to use '@values'?"))
       else
         ()

  return
    if (empty($type))
    then
      $strval
    else
      (: This is crude, but avoids the need for the xdmp-eval privilige. :)
      if ($type = "NCName") then $value cast as xs:NCName
      else if ($type = "NMTOKEN") then $value cast as xs:NMTOKEN
      else if ($type = "NMTOKENS") then $value cast as xs:NMTOKENS
      else if ($type = "Name") then $value cast as xs:Name
      else if ($type = "QName") then $value cast as xs:QName
      else if ($type = "anyURI") then $value cast as xs:anyURI
      else if ($type = "base64Binary") then $value cast as xs:base64Binary
      else if ($type = "boolean") then $value cast as xs:boolean
      else if ($type = "byte") then $value cast as xs:byte
      else if ($type = "date") then $value cast as xs:date
      else if ($type = "dateTime") then $value cast as xs:dateTime
      else if ($type = "decimal") then $value cast as xs:decimal
      else if ($type = "double") then $value cast as xs:double
      else if ($type = "duration") then $value cast as xs:duration
      else if ($type = "float") then $value cast as xs:float
      else if ($type = "gDay") then $value cast as xs:gDay
      else if ($type = "gMonth") then $value cast as xs:gMonth
      else if ($type = "gMonthDay") then $value cast as xs:gMonthDay
      else if ($type = "gYear") then $value cast as xs:gYear
      else if ($type = "gYearMonth") then $value cast as xs:gYearMonth
      else if ($type = "hexBinary") then $value cast as xs:hexBinary
      else if ($type = "int") then $value cast as xs:int
      else if ($type = "integer") then $value cast as xs:integer
      else if ($type = "language") then $value cast as xs:language
      else if ($type = "long") then $value cast as xs:long
      else if ($type = "negativeInteger") then $value cast as xs:negativeInteger
      else if ($type = "nonNegativeInteger") then $value cast as xs:nonNegativeInteger
      else if ($type = "nonPositiveInteger") then $value cast as xs:nonPositiveInteger
      else if ($type = "normalizedString") then $value cast as xs:normalizedString
      else if ($type = "positiveInteger") then $value cast as xs:positiveInteger
      else if ($type = "short") then $value cast as xs:short
      else if ($type = "time") then $value cast as xs:time
      else if ($type = "token") then $value cast as xs:token
      else if ($type = "unsignedByte") then $value cast as xs:unsignedByte
      else if ($type = "unsignedInt") then $value cast as xs:unsignedInt
      else if ($type = "unsignedLong") then $value cast as xs:unsignedLong
      else if ($type = "unsignedShort") then $value cast as xs:unsignedShort
      else if ($type = "string") then $value cast as xs:string
      else
        (rest-impl:log(concat("Invalid type specified in validation: ", $type)),
        error($rest-impl:INVALIDTYPE, $type))
};

(: ====================================================================== :)

declare function rest-impl:process-request(
  $request as element(rest:request),
  $reqenv as map:map
) as map:map
{
  let $trace   := rest-impl:log("processing request")
  let $trace   := rest-impl:dump-reqenv($reqenv)
  let $matches := rest-impl:matches($request, $reqenv, true(), true())[1]
  return
    (: $matches must be a map rest-impl:matches would have raised an error :)
    rest-impl:typed-params($request, $reqenv, $matches)
};

declare function rest-impl:typed-params(
  $req as element(rest:request),
  $reqenv as map:map,
  $params as map:map)
as map:map
{
  let $method := map:get($reqenv, "method")
  let $map := map:map()
  let $_
    := for $param in ($req/rest:uri-param[@as]|$req/rest:param[@as]
                      |rest-impl:http($req,$reqenv)/rest:param[@as]
                      |rest-impl:http($req,$reqenv)/rest:param[@values]
                      |$req/rest:uri-param[@values]|$req/rest:param[@values])
       let $as           := if ($param/@as) then normalize-space($param/@as) else "string"
       let $legal-values := if ($param/@values) then string($param/@values) else ()
       let $values       := map:get($params, $param/@name)
       let $typed-values
         := for $value in $values
            return
              rest-impl:as-atomic-type($value, $as, $legal-values)
       return
         map:put($map, $param/@name, $typed-values)
  let $_
    := for $name in map:keys($params)
       where empty(map:get($map, $name))
       return
         map:put($map, $name, map:get($params, $name))
  return
    $map
};

(: ====================================================================== :)

(: Condition = Or | And | Function | Auth | Accept | UserAgent :)

declare function rest-impl:conditions-match(
  $request as element(rest:request),
  $reqenv as map:map,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $conditions
    := for $elem in ($request/*, rest-impl:http($request,$reqenv)/*)
       where not($elem/self::rest:param
                 or $elem/self::rest:uri-param
                 or $elem/self::rest:http)
       return
         $elem
  return
    if (empty($conditions))
    then
      true()
    else
      rest-impl:and($request, $reqenv, $conditions, $raise-errors)
};

declare private function rest-impl:apply(
  $request as element(rest:request),
  $reqenv as map:map,
  $conditions as element()*,
  $raise-errors as xs:boolean)
as xs:boolean*
{
  for $cond in $conditions
  let $value
    := typeswitch($cond)
       case element(rest:or)
       return rest-impl:or($request, $reqenv, $cond/*, $raise-errors)
       case element(rest:and)
       return rest-impl:and($request, $reqenv, $cond/*, $raise-errors)
       case element(rest:function)
       return rest-impl:function($request, $reqenv, $cond, $raise-errors)
       case element(rest:auth)
       return rest-impl:auth($request, $reqenv, $cond, $raise-errors)
       case element(rest:user-agent)
       return rest-impl:user-agent($request, $reqenv, $cond, $raise-errors)
       case element(rest:accept)
       return rest-impl:accepts-type($request, $reqenv, $cond, $raise-errors)
       default
       return error($rest-impl:INVALIDCONDITION, concat(node-name($cond), " is not a condition"))
  return
    $value
};

declare private function rest-impl:and(
  $request as element(rest:request),
  $reqenv as map:map,
  $conditions as element()*,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $fail := for $result in rest-impl:apply($request, $reqenv, $conditions, $raise-errors)
               where not($result)
               return
                 rest-impl:no-match($raise-errors, $rest-impl:FAILEDCONDITION, "")
  return
    empty($fail)
};

declare private function rest-impl:or(
  $request as element(rest:request),
  $reqenv as map:map,
  $conditions as element()*,
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $pass := for $result in rest-impl:apply($request, $reqenv, $conditions, false())
               where $result
               return
                 true()
  return
    if (not(empty($conditions)) and empty($pass))
    then
      rest-impl:no-match($raise-errors, $rest-impl:FAILEDCONDITION, "")
    else
      true()
};

declare private function rest-impl:function(
  $request as element(rest:request),
  $reqenv as map:map,
  $condition as element(),
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $f := xdmp:function(QName($condition/@ns/string(), $condition/@apply/string()),
                          $condition/@at/string())
  let $uri := map:get($reqenv, "uri")
  let $pass := xdmp:apply($f, $uri, $condition) cast as xs:boolean
  return
    if ($pass)
    then
      true()
    else
      rest-impl:no-match($raise-errors, $rest-impl:FAILEDCONDITION,
                         concat("{", $condition/@ns, "}", $condition/@apply))
};

declare private function rest-impl:auth(
  $request as element(rest:request),
  $reqenv as map:map,
  $condition as element(),
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $kind := if ($condition/rest:kind) then string($condition/rest:kind) else "execute"
  let $pass := xdmp:has-privilege($condition/rest:privilege, $kind)
  return
    if ($pass)
    then
      true()
    else
      rest-impl:no-match($raise-errors, $rest-impl:FAILEDCONDITION,
                         concat($condition/rest:privilege, " ", $kind))
};

declare private function rest-impl:user-agent(
  $request as element(rest:request),
  $reqenv as map:map,
  $condition as element(),
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $ua    := map:get($reqenv, "user-agent")
  let $pass  := matches($ua, $condition)
  let $trace := rest-impl:log(concat("UA: ", $ua, " =?= ", $condition, ": ", $pass))
  return
    if ($pass)
    then
      true()
    else
      rest-impl:no-match($raise-errors, $rest-impl:FAILEDCONDITION, $ua)
};

declare private function rest-impl:accepts-type(
  $request as element(rest:request),
  $reqenv as map:map,
  $condition as element(),
  $raise-errors as xs:boolean)
as xs:boolean
{
  let $accept := map:get($reqenv, "accept")
  let $type  := string($condition)
  let $pass  := rest-impl:types-match($type, $accept, $raise-errors)
  let $trace := rest-impl:log(concat("Accept: ", $condition, ": ", $pass))
  return
    $pass
};

(: ====================================================================== :)

declare function rest-impl:request-environment()
as map:map
{
  let $params := map:map()
  let $_ := for $name in xdmp:get-request-field-names()
            return
              map:put($params, $name, xdmp:get-request-field($name))

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

declare function rest-impl:check-options(
  $options as element(rest:options)
) as element(rest:report)*
{
  (
    let $x := try { validate strict { $options } }
              catch ($e)
              { <rest:report id="REST-SCHEMAINVALID">{$e/*:format-string, $e/*:data}</rest:report> }
    return
      if ($x/self::rest:report)
      then $x
      else ()
    ,
    for $req in $options/rest:request
    return
      rest-impl:check-request($req)
  )
};

declare function rest-impl:check-request(
  $request as element(rest:request)
) as element(rest:report)*
{
  (
    (: must be schema valid :)
    let $x := try { validate strict { $request } }
              catch ($e)
              { <rest:report id="REST-SCHEMAINVALID">{$e/*:format-string, $e/*:data}</rest:report> }
    return
      if ($x/self::rest:report)
      then $x
      else ()
    ,
    (: must identify a known type :)
    for $param in ($request/rest:uri-param[@as], $request//rest:param[@as])
    return
      if (normalize-space($param/@as) = $rest-impl:KNOWN_TYPES)
      then
        ()
      else
        <rest:report id="BAD-TYPE">{string($param/@as)} is not a valid type.</rest:report>
    ,
    (: must list only a single method :)
    for $method in distinct-values(for $method in $request/rest:http/@method
                                   return tokenize($method, '\s+'))
    return
      if (count(rest-impl:http-method($request,$method)) > 1)
      then
        <rest:report id="DUP-METHOD">
          {concat("Duplicate entry for http method: ", $method)}
        </rest:report>
      else
        ()
    ,
    (: cannot be required and have a default :)
    for $param in ($request//rest:param[@required and @default])
    return
      <rest:report id="INVALID">
        {concat($param/@name, " is required and has default")}
      </rest:report>
    ,
    (: cannot have content unless there's a match :)
    for $param in ($request//rest:param[not(@match) and exists(node())])
    return
      <rest:report id="INVALID">
        {concat($param/@name, " has content but no @match")}
      </rest:report>,
    (: cannot have duplicate aliases :)
    let $aliases := for $param in ($request//rest:param[@alias])
                    return
                      tokenize($param/@alias, "\s*\|\s*")
    return
      (for $alias in distinct-values($aliases)
       where count($aliases[.=$alias]) > 1
       return
         <rest:report id="INVALID">
          { concat("Duplicate alias in request: ", $alias) }
         </rest:report>,
       for $alias in $aliases
       where exists($request//rest:param[@name = $alias])
       return
         <rest:report id="INVALID">
          { concat("Alias shadows named parameter: ", $alias) }
         </rest:report>)
  )
};

(: ====================================================================== :)

declare function rest-impl:report-error(
  $error as element(error:error))
as element()
{
  (if ($error/error:code = "SEC-PRIV")
   then xdmp:set-response-code(401, "Unauthorized")
   else xdmp:set-response-code(400, "Bad Request"),
  if (exists(xdmp:get-request-header("Accept")[contains(.,"text/html")]))
  then
    rest-impl:format-error-report($error)
  else
    $error)
};

declare function rest-impl:format-error-report(
  $error as element(error:error))
as element()
{
  <div xmlns="http://www.w3.org/1999/xhtml" style="margin-left: 1em">
    <p>
      { if ($error/error:name != '')
        then
          <b>{string($error/error:name)}: </b>
        else
          ()
      }
      <b>
        { if ($error/error:format-string = "")
          then
            string($error/error:message)
          else
            string($error/error:format-string)
        }
      </b>
    </p>
    { rest-impl:format-error-stack($error/error:stack[1]) }
  </div>
};

declare private function rest-impl:format-error-stack(
  $stack as element(error:stack))
as element()
{
  <div xmlns="http://www.w3.org/1999/xhtml" style="margin-left: 1em">
    { for $frame in $stack/error:frame
      return
        rest-impl:format-error-frame($frame)
    }
  </div>
};

declare private function rest-impl:format-error-frame(
  $frame as element(error:frame))
as element()
{
  <div xmlns="http://www.w3.org/1999/xhtml" style="margin-left: 1em;">
    <div style="margin-top: 1ex;">
      { "In " }
      <tt>{ string($frame/error:uri) }</tt>
      { concat(" on line ", $frame/error:line) }
    </div>
    { if ($frame/error:operation)
      then
        <div style="margin-left: 2em; text-indent: -1em;">
          { concat("In ", $frame/error:operation) }
        </div>
      else
        ()
    }
    { if ($frame/error:variables)
      then
        for $variable in $frame/error:variables/error:variable
        return
          <div style="margin-left: 3em; text-indent: -1em;">
            { concat("$", $variable/error:name, " = ", $variable/error:value) }
          </div>
      else
        ()
    }
  </div>
};
