xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json-query" 
  at "/lib/json-query.xqy" ;

declare variable $json     := xdmp:get-request-field( "json" ) ;
declare variable $path     := xdmp:get-request-field( "path" ) ;
declare variable $got      := json:parse($json) ;
declare variable $valid    := $got = $path ;

try {
$got,
if( $valid ) then () else 
  xdmp:log( ("Got: ", $got, "Expected: ", $path ) ) }
catch ( $e ) {
  fn:concat( "Logged Exception: ", $e//*:message ),
  xdmp:log( ("Exception: ", $e, "JSON: ", $json, "Expected:", $path ) ) }
