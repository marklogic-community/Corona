xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json-path" 
  at "/lib/json-path.xqy" ;

declare variable $json   := xdmp:get-request-field( "json" ) ;
declare variable $parsed := json:parse($json)
declare variable $valid  := fn:false() ;

$valid,
if( $valid ) then () else 
  xdmp:log( ("Got: ", $transformed, "Expected: ", $json ) )