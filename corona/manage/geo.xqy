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
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare option xdmp:mapping "false";


let $params := rest:process-request(endpoints:request("/corona/manage/geo.xqy"))
let $name := map:get($params, "name")
let $requestMethod := xdmp:get-request-method()

let $config := admin:get-configuration()
let $existing := manage:getGeo($name)

return
    if($requestMethod = "GET")
    then
        if(string-length($name))
        then
            if(exists($existing))
            then json:serialize($existing)
            else common:error("corona:GEO-INDEX-NOT-FOUND", "Geospatial index not found", "json")
        else json:serialize(json:array(manage:getAllGeos()))

    else if($requestMethod = "POST")
    then
        if(string-length($name))
        then
            let $key := map:get($params, "key")
            let $element := map:get($params, "element")
            let $attribute := map:get($params, "attribute")
            let $type := map:get($params, "type")
            return

            if((empty($key) and empty($element)) or (exists($key) and exists($element)))
            then common:error("corona:MISSING-PARAMETER", "Must supply either a JSON key, an XML element name or XML element and attribute names", "json")
            else if(exists($attribute) and empty($element))
            then common:error("corona:MISSING-PARAMETER", "Must supply an XML element along with an XML attribute", "json")
            else
                let $key := map:map($params, "key")
                let $element := map:map($params, "element")
                let $childKey := map:map($params, "childKey")
                let $childElement := map:map($params, "childElement")
                let $latKey := map:map($params, "latKey")
                let $longKey := map:map($params, "longKey")
                let $latElement := map:map($params, "latElement")
                let $longElement := map:map($params, "longElement")
                let $latAttribute := map:map($params, "latAttribute")
                let $longAttribute := map:map($params, "longAttribute")
                let $coordinateSystem := map:map($params, "coordinateSystem")
                let $comesFirst := map:map($params, "comesFirst")
                return
                    try {
                        if(exists($element) and exists($latAttribute) and exists($longAttribute))
                        then manage:createGeoWithAttributes($name, $element, $latAttribute, $longAttribute, $coordinateSystem)
                        else if(exists($element) and exists($latElement) and exists($longElement))
                        then manage:createGeoWithElementChildren($name, $element, $latElement, $longElement, $coordinateSystem)
                        else if(exists($key) and exists($latKey) and exists($longKey))
                        then manage:createGeoWithKeyChildren($name, $key, $latKey, $longKey, $coordinateSystem)
                        else if(exists($element) and exists($childElement))
                        then manage:createGeoWithElementChild($name, $element, $childElement, $coordinateSystem, $comesFirst)
                        else if(exists($key) and exists($childKey))
                        then manage:createGeoWithKeyChild($name, $key, $childKey, $coordinateSystem, $comesFirst)
                        else if(exists($element))
                        then manage:createGeoWithElement($name, $element, $coordinateSystem, $comesFirst)
                        else if(exists($key))
                        then manage:createGeoWithKey($name, $key, $coordinateSystem, $comesFirst)
                        else common:error("corona:INVALID-REQUEST", "Invalid geospatial index creation")
                    }
                    catch ($e) {
                        common:errorFromException($e, "json")
                    }
        else common:error("corona:INVALID-PARAMETER", "Must specify a name for the geospatial index", "json")

    else if($requestMethod = "DELETE")
    then
        if(string-length($name))
        then
            if(exists($existing))
            then manage:deleteGeo($name, $config)
            else common:error("corona:GEO-INDEX-NOT-FOUND", "Geospatial index not found", "json")
        else common:error("corona:INVALID-PARAMETER", "Must specify the name of for the geospatial to delete", "json")
    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), "json")
