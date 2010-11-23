xquery version "1.0-ml";

import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

(:
    TODO:
    Copy a document (POST)                  /jsonstore.xqy?uri=http://foo/bar    copyto=http://foo/bar/baz
    Move a document (POST)                  /jsonstore.xqy?uri=http://foo/bar    moveto=http://foo/bar/baz

    DONE:
    Set property (POST)                     /jsonstore.xqy?uri=http://foo/bar    property=foo:bar
    Set permissions (POST) (multiples)      /jsonstore.xqy?uri=http://foo/bar    permission=foo:read&permission=bar:read
    Set collections (POST) (multiples)      /jsonstore.xqy?uri=http://foo/bar    collection=foo&collection=bar
    Set document quality (POST)             /jsonstore.xqy?uri=http://foo/bar    quality=10
    Insert a document (PUT)                 /jsonstore.xqy?uri=http://foo/bar
    Delete a document (DELETE)              /jsonstore.xqy?uri=http://foo/bar
    Get a document (GET)                    /jsonstore.xqy?uri=http://foo/bar
    Get property (GET)                      /jsonstore.xqy?uri=http://foo/bar&property=foo
:)

let $rawOutut := exists(xdmp:get-request-field("raw")[1])
let $fromJSONOutut := exists(xdmp:get-request-field("fromJSON")[1])
let $requestMethod := xdmp:get-request-method()
let $uri := xdmp:get-request-field("uri", ())[1]
let $properties :=
    for $property in xdmp:get-request-field("property", ())
    let $bits := tokenize($property, ":")
    let $name := $bits[1]
    let $value := string-join($bits[2 to last()], ":")
    where exists($name)
    return
        if(count($bits) = 1)
        then QName((), $name)
        else element { $name } { $value }
    
let $permissions :=
    for $permission in xdmp:get-request-field("permission", ())
    let $bits := tokenize($permission, ":")
    let $user := string-join($bits[1 to last() - 1], ":")
    let $access := $bits[last()]
    where exists($user) and $access = ("update", "read", "execute")
    return xdmp:permission($user, $access)

let $collections := xdmp:get-request-field("collection", ())
let $quality := xs:integer(xdmp:get-request-field("quality", "0"))

let $bodyContent := xdmp:get-request-body("text")
let $documentBody := json:jsonToXML($bodyContent, true())

return
    if($requestMethod = "GET")
    then 
        if(empty($properties))
        then 
            if($rawOutut)
            then doc($uri)
            else if($fromJSONOutut)
            then <foo>{ xdmp:from-json(json:xmlToJson(doc($uri)/*)) }</foo>/*
            else json:xmlToJson(doc($uri)/*)
        else xdmp:document-get-properties($uri, $properties)
    else if($requestMethod = "DELETE")
    then xdmp:document-delete($uri)
    else if($requestMethod = "PUT")
    then xdmp:document-insert($uri, $documentBody, $permissions, $collections, $quality)
    else if($requestMethod = "POST")
    then (
        if(exists($properties))
        then xdmp:document-set-properties($uri, $properties)
        else ()
        ,
        if(exists($permissions))
        then xdmp:document-set-permissions($uri, $permissions)
        else ()
        ,
        if(exists($collections))
        then xdmp:document-set-collections($uri, $collections)
        else ()
        ,
        if(exists(xdmp:get-request-field("quality")))
        then xdmp:document-set-quality($uri, $quality)
        else ()
    )
    else ()
