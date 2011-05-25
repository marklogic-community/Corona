xquery version "1.0";

module namespace json="http://marklogic.com/json";
declare default function namespace "http://marklogic.com/json";

declare function jsonToXML($json as xs:string)
{
  let $res := _parseValue(_tokenize($json))
  return
    if(fn:exists(fn:remove($res,1))) then fn:error()
    else document { element json {
      $res[1]/@*,
      $res[1]/node()
    }}
};

declare (:private:) function _parseValue($tokens as element(token)*)
{
  let $token := $tokens[1]
  let $tokens := fn:remove($tokens,1)
  return
    if($token/@t = "lbrace") then (
      let $res := _parseObject($tokens)
      let $tokens := fn:remove($res,1)
      return (
        element res {
          attribute type { "object" },
          $res[1]/node()
        },
        $tokens
      )
    ) else if ($token/@t = "lsquare") then (
      let $res := _parseArray($tokens)
      let $tokens := fn:remove($res,1)
      return (
        element res {
          attribute type { "array" },
          $res[1]/node()
        },
        $tokens
      )
    ) else if ($token/@t = "number") then (
      element res {
        attribute type { "number" },
        text { $token }
      },
      $tokens
    ) else if ($token/@t = "string") then (
      element res {
        attribute type { "string" },
        text { _unescapeJSONString($token) }
      },
      $tokens
    ) else if ($token/@t = "true" or $token/@t = "false") then (
      element res {
        attribute boolean { $token }
      },
      $tokens
    ) else if ($token/@t = "null") then (
      element res {
        attribute type { "null" }
      },
      $tokens
    ) else fn:error(xs:QName("json:PARSE01"),
      fn:concat("Unexpected token: ", fn:string($token/@t), " (""", fn:string($token), """)"))
};

declare (:private:) function _parseObject($tokens as element(token)*)
{
  let $token1 := $tokens[1]
  let $tokens := fn:remove($tokens,1)
  return
    if(fn:not($token1/@t = "string")) then fn:error() else
      let $token2 := $tokens[1]
      let $tokens := fn:remove($tokens,1)
      return
        if(fn:not($token2/@t = "colon")) then fn:error() else
          let $res := _parseValue($tokens)
          let $tokens := fn:remove($res,1)
          let $pair := element { _escapeNCName($token1) } {
            $res[1]/@*,
            $res[1]/node()
          }
          let $token := $tokens[1]
          let $tokens := fn:remove($tokens,1)
          return
            if($token/@t = "comma") then (
              let $res := _parseObject($tokens)
              let $tokens := fn:remove($res,1)
              return (
                element res {
                  $pair,
                  $res[1]/node()
                },
                $tokens
              )
            ) else if($token/@t = "rbrace") then (
              element res {
                $pair
              },
              $tokens
            ) else fn:error(xs:QName("json:PARSE02"),
              fn:concat("Unexpected token: ", fn:string($token/@t), " (""", fn:string($token), """)"))
};

declare (:private:) function _parseArray($tokens as element(token)*)
{
  let $res := _parseValue($tokens)
  let $tokens := fn:remove($res,1)
  let $item := element item {
    $res[1]/@*,
    $res[1]/node()
  }
  let $token := $tokens[1]
  let $tokens := fn:remove($tokens,1)
  return
    if($token/@t = "comma") then (
      let $res := _parseArray($tokens)
      let $tokens := fn:remove($res,1)
      return (
        element res {
          $item,
          $res[1]/node()
        },
        $tokens
      )
    ) else if($token/@t = "rsquare") then (
      element res {
        $item
      },
      $tokens
    ) else fn:error()
};

declare (:private:) function _tokenize($json as xs:string)
  as element(token)*
{
  let $tokens := ("\{", "\}", "\[", "\]", ":", ",", "true", "false", "null", "\s+",
    '"([^"\\]|\\"|\\\\|\\/|\\b|\\f|\\n|\\r|\\t|\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])*"',
    "-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?")
  let $regex := fn:string-join(for $t in $tokens return fn:concat("(",$t,")"),"|")
  for $match in fn:analyze-string($json, $regex)/*
  return
    if($match/self::*:non-match) then _token("error", fn:string($match))
    else if($match/*:group/@nr = 1) then _token("lbrace", fn:string($match))
    else if($match/*:group/@nr = 2) then _token("rbrace", fn:string($match))
    else if($match/*:group/@nr = 3) then _token("lsquare", fn:string($match))
    else if($match/*:group/@nr = 4) then _token("rsquare", fn:string($match))
    else if($match/*:group/@nr = 5) then _token("colon", fn:string($match))
    else if($match/*:group/@nr = 6) then _token("comma", fn:string($match))
    else if($match/*:group/@nr = 7) then _token("true", fn:string($match))
    else if($match/*:group/@nr = 8) then _token("false", fn:string($match))
    else if($match/*:group/@nr = 9) then _token("null", fn:string($match))
    else if($match/*:group/@nr = 10) then () (:ignore whitespace:)
    else if($match/*:group/@nr = 11) then
      let $v := fn:string($match)
      let $len := fn:string-length($v)
      return _token("string", fn:substring($v, 2, $len - 2))
    else if($match/*:group/@nr = 13) then _token("number", fn:string($match))
    else _token("error", fn:string($match))
};

declare (:private:) function _token($t, $value)
{
  <token t="{$t}">{ fn:string($value) }</token>
};

declare function xmlToJSON(
    $element as element()
) as xs:string
{
  fn:string-join(processElement($element),"")
};

declare (:private:) function processElement($element as element())
  as xs:string*
{
  if($element/@type = "object") then outputObject($element)
  else if($element/@type = "array") then outputArray($element)
  else if($element/@type = "null") then "null"
  else if(fn:exists($element/@boolean)) then xs:string($element/@boolean)
  else if($element/@type = "number") then xs:string($element)
  else ('"', _escapeJSONString($element), '"')
};

declare (:private:) function outputObject($element as element())
  as xs:string*
{
  "{",
  for $child at $pos in $element/*
  return (
    if($pos = 1) then () else ",",
    '"', _unescapeNCName(fn:local-name($child)), '":', processElement($child)
  ),
  "}"
};

declare (:private:) function outputArray($element as element())
  as xs:string*
{
  "[",
  for $child at $pos in $element/*
  return (
    if($pos = 1) then () else ",",
    processElement($child)
  ),
  "]"
};

declare (:private:) function _decodeHexChar($val as xs:integer)
  as xs:integer
{
  let $tmp := $val - 48 (: '0' :)
  let $tmp := if($tmp <= 9) then $tmp else $tmp - (65-48) (: 'A'-'0' :)
  let $tmp := if($tmp <= 15) then $tmp else $tmp - (97-65) (: 'a'-'A' :)
  return $tmp
};

declare (:private:) function _decodeHexStringHelper($chars as xs:integer*, $acc as xs:integer)
  as xs:integer
{
  if(fn:empty($chars)) then $acc
  else _decodeHexStringHelper(fn:remove($chars,1), ($acc * 16) + _decodeHexChar($chars[1]))
};

declare (:private:) function _decodeHexString($val as xs:string)
  as xs:integer
{
  _decodeHexStringHelper(fn:string-to-codepoints($val), 0)
};

declare (:private:) function _unescapeJSONString($val as xs:string)
  as xs:string
{
  fn:string-join(
    let $regex := '[^\\]+|(\\")|(\\\\)|(\\/)|(\\b)|(\\f)|(\\n)|(\\r)|(\\t)|(\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])'
    for $match in fn:analyze-string($val, $regex)/*
    return 
      if($match/*:group/@nr = 1) then """"
      else if($match/*:group/@nr = 2) then "\"
      else if($match/*:group/@nr = 3) then "/"
      (: else if($match/*:group/@nr = 4) then "&#x08;" :)
      (: else if($match/*:group/@nr = 5) then "&#x0C;" :)
      else if($match/*:group/@nr = 6) then "&#x0A;"
      else if($match/*:group/@nr = 7) then "&#x0D;"
      else if($match/*:group/@nr = 8) then "&#x09;"
      else if($match/*:group/@nr = 9) then
        fn:codepoints-to-string(_decodeHexString(fn:substring($match, 3)))
      else fn:string($match)
  ,"")
};

(: Need to backslash escape any double quotes, backslashes, and newlines :)
declare (:private:) function _escapeJSONString($string as xs:string)
  as xs:string
{
    let $string := fn:replace($string, "\\", "\\\\")
    let $string := fn:replace($string, """", "\\""")
    let $string := fn:replace($string, fn:codepoints-to-string((13, 10)), "\\n")
    let $string := fn:replace($string, fn:codepoints-to-string(13), "\\n")
    let $string := fn:replace($string, fn:codepoints-to-string(10), "\\n")
    return $string
};

declare (:private:) function _encodeHexStringHelper($num as xs:integer, $digits as xs:integer)
  as xs:string*
{
  if($digits > 1) then _encodeHexStringHelper($num idiv 16, $digits - 1) else (),
  ("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")[$num mod 16 + 1]
};

declare (:private:) function _escapeNCName($val as xs:string)
  as xs:string
{
  fn:string-join(
    let $regex := ':|_|(\i)|(\c)|.'
    for $match at $pos in fn:analyze-string($val, $regex)/*
    return
      if($match/*:group/@nr = 1 or
        ($match/*:group/@nr = 2 and $pos != 1)) then fn:string($match)
      else ("_", _encodeHexStringHelper(fn:string-to-codepoints($match), 4))
  ,"")
};

declare (:private:) function _unescapeNCName($val as xs:string)
  as xs:string
{
  fn:string-join(
    let $regex := '(_[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])|[^_]+'
    for $match at $pos in fn:analyze-string($val, $regex)/*
    return
      if($match/*:group/@nr = 1) then
        fn:codepoints-to-string(_decodeHexString(fn:substring($match, 2)))
      else fn:string($match)
  ,"")
};

