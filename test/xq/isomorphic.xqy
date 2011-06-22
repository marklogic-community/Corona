xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" 
  at "/lib/json.xqy" ;

declare variable $json := xdmp:get-request-field( "json" ) ;
declare variable $transformed :=
  fn:string( json:xmlToJSON( json:jsonToXML( $json )/* ) ) ;
declare variable $valid := $json = $transformed ;

try {
$transformed,
if( $valid ) then () else 
  xdmp:log( ("Got: ", $transformed, "Expected: ", $json ) ) }
catch ( $e ) {
  fn:concat( "Logged Exception: ", $e//*:message ),
  xdmp:log( ("Exception: ", $e, "Expected: ", $json ) ) }