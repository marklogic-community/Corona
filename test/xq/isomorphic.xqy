xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json" 
  at "/lib/json.xqy" ;

declare variable $json := xdmp:get-request-field( "json" ) ;

$json = fn:string( json:xmlToJSON( json:jsonToXML( $json )/* ) )