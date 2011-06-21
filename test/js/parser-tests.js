function isoUrl(json) { return '/test/xq/isomorphic.xqy?json=' + escape(json) }
function parseUrl(json, path) { return '/test/xq/parse.xqy?json=' + escape(json) 
  + '&path=' + escape(path) }

function isomorphic(json, success, error) {
  asyncTest(json, function() {
    $.ajax( { url: isoUrl(json)
    , success: success
    , error: error
    , complete: function() { start(); } }) }) }

function isIsomorphic(json) {
  isomorphic( json, 
    function(d,t,j) { equals(d, 'true', 'OK') },
    function(j,t,e) { ok(false, 'NOK') } ) }

function parseable(json, path, success, error) {
  asyncTest(json, function() {
    $.ajax( { url: parseUrl(json, path)
    , success: success
    , error: error
    , complete: function() { start(); } }) }) }

function parsingOk(json, path) {
  parseable( json, path,
    function(d,t,j) { equals(d, path, 'OK') },
    function(j,t,e) { ok(false, 'NOK') } ) }

validJSON = [
  { "json": 'true'
  , "path": '/json' }
, { "json": 'false'
  , "path": '/json' } 
, { "json": '[]'
  , "path": '/json' }
, { "json": 'null'
  , "path": '/json' }
, { "json": '{}'
  , "path": '/json' }
, { "json": '{unquotedKey:[]}'
  , "path": '/json' }
, { "json": '{"whitespace": false}'
  , "path": '/json' }
, { "json": '{"false":"false()"}'
  , "path": '/json' }
, { "json": '["hello","world",[],{},null,false,true]'
  , "path": '/json' }
, { "json": '{"quoted": "This sentence is \"quoted\"}'
  , "path": '/json' }
, { "json": '["new\nline"]'
  , "path": '/json' }
, { "json": '{"bad key":true}'
  , "path": '/json' }
, { "json": '{"flowStatus":{"collector":{"id":"17498595829529319667","uri":"collector-zip.xqy","name":"Filesystem Zip Directory","summary":"Load the contents of zip files from this directory on the server: /home/rgrimm/content","hasConfig":true,"valid":true},"transforms":null,"databaseCount":"4027","tickets":{"ticketStatus":[{"current":"false","longRunning":false,"has-transforms":"false","state":"completed","startTime":"23 Sep 2010 16:59:50","progress":100,"timeConsumed":"2 second(s)","errors":0,"totalDocuments":8,"documentsProcessed":8,"ticketId":"/tickets/ticket/10017106554991392235","collectorId":"17498595829529319667","destinationCount":8},{"current":"false","longRunning":false,"has-transforms":"false","state":"completed","startTime":"23 Sep 2010 16:59:38","progress":100,"timeConsumed":"2 second(s)","errors":0,"totalDocuments":8,"documentsProcessed":8,"ticketId":"/tickets/ticket/12813359101084061157","collectorId":"17498595829529319667","destinationCount":0},{"current":"false","longRunning":false,"has-transforms":"false","state":"completed","startTime":"23 Sep 2010 15:12:33","progress":100,"timeConsumed":"35 second(s)","errors":0,"totalDocuments":3455,"documentsProcessed":3455,"ticketId":"/tickets/ticket/17976873322921528925","collectorId":"17498595829529319667","destinationCount":3447},{"current":"false","longRunning":false,"has-transforms":"false","state":"completed","startTime":"23 Sep 2010 15:08:34","progress":100,"timeConsumed":"35 second(s)","errors":0,"totalDocuments":3455,"documentsProcessed":3455,"ticketId":"/tickets/ticket/14854376546708590679","collectorId":"17498595829529319667","destinationCount":0},{"current":"false","longRunning":false,"has-transforms":"false","state":"completed","startTime":"23 Sep 2010 15:06:57","progress":100,"timeConsumed":"35 second(s)","errors":0,"totalDocuments":3455,"documentsProcessed":3455,"ticketId":"/tickets/ticket/10304857462729133110","collectorId":"17498595829529319667","destinationCount":0}]}}}'
  , "path": '/json' }
, { "json": '{"in_reply_to_status_id_str":null,"place":null,"coordinates":null,"in_reply_to_status_id":null,"in_reply_to_user_id":null,"favorited":false,"in_reply_to_user_id_str":null,"contributors":null,"in_reply_to_screen_name":null,"id_str":29609921000,"source":"Nike Application","retweet_count":null,"created_at":"Wed Nov 03 21:58:06 +0000 2010","retweeted":false,"user":{"statuses_count":1869,"favourites_count":67,"profile_sidebar_border_color":"eeeeee","description":"2009年9月にダイエットと体力作りを目指しランニング開始。2010年7月にフルマラソン完走(3時間44分)。次は3時間半切りを目指します。アイコンはNike+チャレンジでGetしたお守りです。Computing,Soccer,foursquare,waze,Guitar,HR/HM","screen_name":"vori3","show_all_inline_media":false,"contributors_enabled":false,"time_zone":"Tokyo","friends_count":0,"profile_background_color":"131516","id_str":13885402,"followers_count":0,"url":"http://vori3.blog74.fc2.com/","geo_enabled":false,"profile_use_background_image":true,"profile_text_color":"333333","follow_request_sent":null,"lang":"ja","created_at":"Sun Feb 24 01:09:11 +0000 2008","location":"Tokyo","verified":false,"profile_background_image_url":"http://s.twimg.com/a/1288374569/images/themes/theme14/bg.gif","profile_link_color":"009999","protected":false,"name":"vori3","following":null,"profile_background_tile":true,"profile_sidebar_fill_color":"efefef","profile_image_url":"http://a0.twimg.com/profile_images/840553288/vori3_normal.jpg","id":13885402,"listed_count":3,"notifications":null,"utc_offset":32400}"geo":null,"id":29609921000,"truncated":false,"text":"は 2010/11/4 at 5:50 AM に 6\'45"/km のペースで 8.42 km を走りました http://go.nike.com/9rlcovd" }'
  , "path": '/json' }
, { "json": '{"in_reply_to_status_id_str":null,"place":null,"coordinates":{"coordinates":[-69.940075,18.470168],"type":"Point"},"in_reply_to_status_id":null,"in_reply_to_user_id":null,"favorited":false,"in_reply_to_user_id_str":null,"contributors":null,"in_reply_to_screen_name":null,"id_str":"29615391000","source":"<a href=\"http://www.ubertwitter.com/bb/download.php\" rel=\"nofollow\">ÜberTwitter</a>","retweet_count":null,"created_at":"Wed Nov 03 23:05:39 +0000 2010","retweeted":false,"user":{"follow_request_sent":null,"favourites_count":3,"profile_sidebar_border_color":"65B0DA","description":"Psicologa :)Amo a Dios,Soy altruista,Aventurera,fantatica d (LA LUNA),m gusta:sonreir,viajar,Leer,Escribir y Lucho por los niños AUTISTA. Muy FELIZ:D Follow Me","screen_name":"AnaHildaMedina","verified":false,"time_zone":"Quito","profile_background_color":"642D8B","id_str":"77391456","listed_count":13,"followers_count":288,"url":"http://anahildamedina.blogspot.com","statuses_count":14257,"profile_use_background_image":true,"profile_text_color":"3D1957","show_all_inline_media":false,"lang":"es","created_at":"Sat Sep 26 04:00:27 +0000 2009","location":"ÜT: 18.470168,-69.940075","contributors_enabled":false,"profile_background_image_url":"http://s.twimg.com/a/1288742912/images/themes/theme10/bg.gif","profile_link_color":"FF0000","protected":false,"friends_count":199,"name":"Ana Hilda Medina","following":null,"profile_background_tile":true,"profile_sidebar_fill_color":"7AC3EE","profile_image_url":"http://a3.twimg.com/profile_images/1156053907/201917112_normal.jpg","id":77391456,"geo_enabled":true,"notifications":null,"utc_offset":-18000},"geo":{"coordinates":[18.470168,-69.940075],"type":"Point"},"id":29615391000,"truncated":false,"text":"Q quiere d aqui? No m puedo mover! RT @AlxRodz: @AnaHildaMedina Yo he ido! http://myloc.me/dOBlY"}'
  , "path": '/json' }
, { "json": '"\u304a\u3044\u304a\u3044\u3069\u3046\u3057\u3066\u8abf\u5b50\u304c\u60aa\u3044\u306e\uff57\uff57\uff57\uff57"'
  , "path": '/json' }
, { "json": '{"key":"book","value":["0596000405"],"comparison":"=","orPredicate":[{"key":"book","value":"0596000405"},{"key":"article","value":"0596000405"}],"andPredicate":[],"descendant":{},"position":"1 to last()"}'
  , "path": '/json[book = ("0596000405")]' }
, { "json": '{"key":"id","value":["0596000405","123456789"],"comparison":"=","orPredicate":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"andPredicate":[],"descendant":{},"position":"1 to last()"}'
  , "path": '/json[id = ("0596000405", "123456789")]' }
, { "json": '{"fulltext":{"or":[{"equals":{"key":"greeting","string":"Hello World","weight":2.0,"caseSensitive":false,"diacriticSensitive":true,"punctuationSensitve":false,"whitespaceSensitive":false,"stemmed":true,"wildcarded":true,"minimumOccurances":1,"maximumOccurances":null}},{"contains":{"key":"para","string":"Hello World","weight":1.0}},{"range":{"key":"para","value":"Hello World","weight":1.0,"operator":"="}},{"geo":{"parent":"location","latKey":"latitude","longKey":"longitude","key":"latlong","region":[{"point":{"longitude":12,"latitude":53}},{"circle":{"longitude":12,"latitude":53,"radius":10}},{"box":{"north":3,"east":4,"south":-5,"west":-6}},{"polygon":[{"longitude":12,"latitude":53},{"longitude":15,"latitude":57},{"longitude":12,"latitude":53}]}]}},{"collection":"foo"}],"filtered":false,"score":"logtfidf"}}'
  , "path": 'cts:search(/json, cts:or-query((cts:element-value-query(fn:QName("", "greeting"), "Hello World", ("case-insensitive","diacritic-sensitive","punctuation-insensitive","whitespace-insensitive","stemmed","wildcarded","lang=en"), 2), cts:element-word-query(fn:QName("", "para"), "Hello World", ("lang=en"), 1), cts:element-range-query(fn:QName("", "para"), "=", "Hello World", ("collation=http://marklogic.com/collation/"), 1), cts:element-pair-geospatial-query(fn:QName("", "location"), fn:QName("", "latitude"), fn:QName("", "longitude"), (cts:point("53,12"), cts:circle("@10 53,12"), cts:box("[-5, -6, 3, 4]"), cts:polygon("53,12 57,15 53,12")), ("coordinate-system=wgs84"), 1), cts:collection-query("foo"))), ("unfiltered", "score-logtfidf"), 1)' }
, { "json": '{"email":"notreal@marklogic.com","position":"","name":"Not Real","affiliation":"MarkLogic","id":"43450202293176688","bio":""}'
  , "path": '/json' }
, { "json": '{"email":"someone@company.org","position":"Software Developer ","name":"Joe Doe","affiliation":"Company","id":"93976451761512432","bio":"Apart from living life with his wondrous family, Joe often finds himself with his hands on home row, typing with the intensity of a puma. \"To me, time at the keyboard with a good SDK is exactly like an artist at his canvas, only with a different palette,\" he says. He believes software is a fantastic creative medium because of its extreme malleability and availability. \"Anyone with a computer with an Internet connection has a fantastic opportunity to create something out of nothing that is original, useful, and beautiful.\" As of late, many of Joes creations have found new life on the MarkLogic platform. Working at the LDS Church, his teams have produced the new mormon.org, parts of lds.org, and are continuing to develop multiple new products for several missionary audiences. \"Its the golden age of software dev on the web,\" he declares. And who can doubt it, given the twinkle in his eye and not-so-subtle grin as he says it? Joe is excited to attend and share the MarkLogic love at this years conference and invites you to attend. "}'
  , "path": '/json' }
, { "json": '{"track":"Customer Applications","speakers":["12990260000581700"],"endTime":"2011-04-29T12:15:00","id":"71515911288012288","title":"Secure Information Discovery in the WikiLeaks Era","plenary":false,"startTime":"2011-04-29T11:15:00","abstract":"How do you allow users to share and discover information in a classified environment?  ENSCO, Inc. has developed an innovative security application that allows users to ascertain the existence of documents without compromising access to the information.  See an example of a successful implementation of obtaining knowledge of the existence, but not necessarily the content, of  classified information.   \nWikiLeaks has illustrated that it is critically important to know what a user is doing.  Agencies must possess the ability to know who saw what, and when.  ENSCO has addressed this through the creation of an auditing service.   You will learn how this service tracks each users queries and provides a vehicle to monitor all access activities.\n"}'
  , "path": '/json' }
, { "json": '{"key":"book","comparison":"=","or":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"and":[],"innerKey":{},"position":"1 to last()"}'
  , "path": '/json[exists(book)][id = "0596000405" or other_id = "0596000405"]' }
, { "json": '{"key":"book","value":{"key":"id","value":"0596000405"},"comparison":"=","or":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"and":[],"innerKey":{},"position":"1 to last()"}'
  , "path": '/json[book/id = "0596000405"][id = "0596000405" or other_id = "0596000405"]' }
, { "json": '{"key":"book","value":{"key":"id"},"comparison":"=","or":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"and":[],"innerKey":{},"position":"1 to last()"}'
  , "path": '/json[exists(book/id)][id = "0596000405" or other_id = "0596000405"]' }
, { "json": '{"key":"book","value":{"innerKey":"id","value":["0596000405","123456789"]},"comparison":"=","or":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"and":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"position":"1 to last()"}'
  , "path": '/json[book//id = ("0596000405", "123456789")][id = "0596000405" or other_id = "0596000405"][id = "0596000405" and other_id = "0596000405"]' }
, { "json": '{"key":"book","value":{"innerKey":"id","value":["0596000405","123456789"]},"or":[{"key":"id","value":"0596000405"},{"key":"other_id","value":"0596000405"}],"position":"1 to 10"}'
  , "path": '(/json[book//id = ("0596000405", "123456789")][id = "0596000405" or other_id = "0596000405"])[1 to 10]' }
]

// TODO: UTF-8 params not working with qunit
$(document).ready(function(){
  module("Isomorphic") ;
    // Missing Invalid JSON
    for (var i = validJSON.length - 1; i >= 0; i--) {
      isIsomorphic(validJSON[i].json) }
  module("Parser") ;
    // Missing Invalid JSON
    for (var i = validJSON.length - 1; i >= 0; i--) {
      if (validJSON[i].path) { 
        parsingOk(validJSON[i].json, validJSON[i].path) } }
  // Missing REST
  // Missing Update Functions
})
