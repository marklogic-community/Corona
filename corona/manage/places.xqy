(:
Copyright 2011 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

xquery version "1.0-ml";

import module namespace manage="http://marklogic.com/corona/manage" at "../lib/manage.xqy";
import module namespace common="http://marklogic.com/corona/common" at "../lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "../lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "../lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/corona/manage/places.xqy"))
let $requestMethod := xdmp:get-request-method()
let $scope := map:get($params, "scope")
let $name := map:get($params, "name")
let $mode := map:get($params, "mode")

let $key := map:get($params, "key")
let $element := map:get($params, "element")
let $attribute := map:get($params, "attribute")
let $type := map:get($params, "type")
let $weight := map:get($params, "weight")

let $name := if(string-length($name)) then $name else () 
let $scope := if(starts-with($scope, "places")) then "places" else "place"

return
    try {
        if($requestMethod = "GET")
        then
            if($scope = "place" and empty($name))
            then json:serialize(manage:getPlace(()))
            else if($scope = "places" and empty($name))
            then json:serialize(json:array(manage:getAllPlaces()))
            else if(exists($name))
            then json:serialize(manage:getPlace($name))
            else common:error(400, "corona:INVALID-REQUEST", "Must supply a place name, request all the places or the anonymous place", "json")

        else if($requestMethod = "PUT")
        then
            if($scope = "place" and exists($name))
            then manage:createPlace($name, $mode)
            else if($scope = "places")
            then common:error(400, "corona:INVALID-REQUEST", "Can not create a new place under /manage/places, use /manage/place instead", "json")
            else common:error(400, "corona:INVALID-INDEX-NAME", "The anonymous place is automatically created for you. Must supply a name for the place when creating.", "json")

        else if($requestMethod = "POST")
        then
            if(exists($key))
            then manage:addKeyToPlace($name, $key, $type, $weight)
            else if(exists($element) and exists($attribute))
            then manage:addAttributeToPlace($name, $element, $attribute, $type, $weight)
            else if(exists($element))
            then manage:addElementToPlace($name, $element, $type, $weight)
            else common:error(400, "corona:INVALID-REQUEST", "Must specify a key, element or element/attribute pair to add to the place", "json")

        else if($requestMethod = "DELETE")
        then
            if(exists($key))
            then manage:removeKeyFromPlace($name, $key, $type)
            else if(exists($element) and exists($attribute))
            then manage:removeAttributeFromPlace($name, $element, $attribute, $type)
            else if(exists($element))
            then manage:removeElementFromPlace($name, $element, $type)
            else common:error(400, "corona:INVALID-REQUEST", "Must specify a key, element or element/attribute pair to remove from the place", "json")
        else common:error(500, "corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
    }
    catch ($e) {
        common:errorFromException(400, $e, "json")
    }
