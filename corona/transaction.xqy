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

import module namespace common="http://marklogic.com/corona/common" at "lib/common.xqy";
import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "lib/rest/rest.xqy";
import module namespace endpoints="http://marklogic.com/corona/endpoints" at "/config/endpoints.xqy";

declare namespace corona="http://marklogic.com/corona";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/corona/transaction.xqy"))

let $requestMethod := xdmp:get-request-method()
let $action := map:get($params, "action")
let $txid := map:get($params, "txid")
let $outputFormat := common:getOutputFormat((), map:get($params, "outputFormat"))

let $errors :=
    if($action = "create" and exists($txid))
    then common:error("corona:INVALID-PARAMETER", "Don't supply a transaction ID when creating a transaction", $outputFormat)
    else if($action = ("status", "commit", "rollback") and empty($txid))
    then common:error("corona:INVALID-PARAMETER", "Must supply a transaction ID when getting the status, committing or rolling backing a transaction", $outputFormat)
    else ()

return
    if(exists($errors))
    then $errors
    else 

    if($requestMethod = "POST")
    then
        if($action = "create")
        then
            let $id := xdmp:transaction-create()
            let $set := xdmp:set-transaction-name("corona-transaction", xdmp:host(), $id)
            let $txid := concat(xdmp:host(), ":", $id)
            return
                if($outputFormat = "json")
                then json:serialize(json:document(json:object((
                    "txid", $txid
                ))))
                else <corona:response>
                    <corona:txid>{ $txid }</corona:txid>
                </corona:response>

        else if($action = "rollback")
        then try {
            let $idMap := common:processTXID($txid, false())
            let $rollback := xdmp:transaction-rollback(map:get($idMap, "hostID"), map:get($idMap, "id"))
            return xdmp:set-response-code(204, "Transaction rolled back")
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }

        else if($action = "commit")
        then try {
            let $idMap := common:processTXID($txid, false())
            let $commit := xdmp:transaction-commit(map:get($idMap, "hostID"), map:get($idMap, "id"))
            return xdmp:set-response-code(204, "Transaction committed")
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }

        else common:error("corona:INVALID-REQUEST", "Must spcify an action of create, rollback or commit", $outputFormat)

    else if($requestMethod = "GET")
    then 
        if($action = "status")
        then try {
            let $idMap := common:processTXID($txid, false())
            let $currentTransactions := xdmp:transaction("corona-transaction", map:get($idMap, "hostID"))
            let $exists := $currentTransactions = map:get($idMap, "id")
            return
                if($outputFormat = "json")
                then json:serialize(json:document(json:object((
                    "txid", $txid,
                    "active", $exists
                ))))
                else <corona:response>
                    <corona:txid>{ $txid }</corona:txid>
                    <corona:active>{ $exists }</corona:active>
                </corona:response>
        }
        catch ($e) {
            common:errorFromException($e, $outputFormat)
        }
        else common:error("corona:INVALID-PARAMETER", concat("Invalid action '", $action, "', GET requests only support returning transaction status."), $outputFormat)

    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), $outputFormat)
