function isoUrl(json) { return '/test/xq/isomorphic.xqy?json=' + escape(json) }

function isomorphic( json, success, error ) {
  asyncTest(json, function() {
    $.ajax( { url: isoUrl(json)
    , success: success
    , error: error
    , complete: function() { start(); } }) }) }

function isIsomorphic( json ) {
  isomorphic( json, 
    function(d,t,j) { equals(d, 'true', "OK") },
    function(j,t,e) { ok(false, "NOK") } ) }

validJSON = [
  'true', 'false', '[]'
]

$(document).ready(function(){
  module("Parser/Compiler") ;
    for (var i = validJSON.length - 1; i >= 0; i--){
      isIsomorphic(validJSON[i]) };
    // Invalid JSON
  // REST
  // Update Functions
})

