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
        then try {
            let $functions := (
                xdmp:function(xs:QName("xdmp:transaction-create")),
                xdmp:function(xs:QName("xdmp:set-transaction-name"))
            )
            let $id := xdmp:apply($functions[1], <options xmlns="xdmp:eval"><transaction-mode>update</transaction-mode></options>)
            let $set := xdmp:apply($functions[2], "corona-transaction", xdmp:host(), $id)
            let $txid := concat(xdmp:host(), ":", $id)
            return
                if($outputFormat = "json")
                then json:serialize(json:document(json:object((
                    "txid", $txid
                ))))
                else <corona:response>
                    <corona:txid>{ $txid }</corona:txid>
                </corona:response>
        }
        catch ($e) {
            if($e/*:code = "XDMP-UNDFUN" and $e/*:data/*:datum = ("xdmp:transaction-create()", "xdmp:set-transaction-name()"))
            then common:error("corona:INVALID-REQUEST", "This version of MarkLogic Server does not support transactions.  Upgrade to 5.0 or greater.", $outputFormat)
            else common:errorFromException($e, $outputFormat)
        }

        else if($action = "rollback")
        then try {
            let $rollbackFN := xdmp:function(xs:QName("xdmp:transaction-rollback"))
            let $idMap := common:processTXID($txid, false())
            let $rollback := xdmp:apply($rollbackFN, map:get($idMap, "hostID"), map:get($idMap, "id"))
            return xdmp:set-response-code(204, "Transaction rolled back")
        }
        catch ($e) {
            if($e/*:code = "XDMP-UNDFUN" and $e/*:data/*:datum = "xdmp:transaction-rollback()")
            then common:error("corona:INVALID-REQUEST", "This version of MarkLogic Server does not support transactions.  Upgrade to 5.0 or greater.", $outputFormat)
            else common:errorFromException($e, $outputFormat)
        }

        else if($action = "commit")
        then try {
            let $commitFN := xdmp:function(xs:QName("xdmp:transaction-commit"))
            let $idMap := common:processTXID($txid, false())
            let $commit := xdmp:apply($commitFN, map:get($idMap, "hostID"), map:get($idMap, "id"))
            return xdmp:set-response-code(204, "Transaction committed")
        }
        catch ($e) {
            if($e/*:code = "XDMP-UNDFUN" and $e/*:data/*:datum = "xdmp:transaction-commit()")
            then common:error("corona:INVALID-REQUEST", "This version of MarkLogic Server does not support transactions.  Upgrade to 5.0 or greater.", $outputFormat)
            else common:errorFromException($e, $outputFormat)
        }

        else common:error("corona:INVALID-REQUEST", "Must spcify an action of create, rollback or commit", $outputFormat)

    else if($requestMethod = "GET")
    then 
        if($action = "status")
        then try {
            let $transactionFN := xdmp:function(xs:QName("xdmp:transaction"))
            let $idMap := common:processTXID($txid, false())
            let $currentTransactions := xdmp:apply($transactionFN, "corona-transaction", map:get($idMap, "hostID"))
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
            if($e/*:code = "XDMP-UNDFUN" and $e/*:data/*:datum = "xdmp:transaction()")
            then common:error("corona:INVALID-REQUEST", "This version of MarkLogic Server does not support transactions.  Upgrade to 5.0 or greater.", $outputFormat)
            else common:errorFromException($e, $outputFormat)
        }
        else common:error("corona:INVALID-PARAMETER", concat("Invalid action '", $action, "', GET requests only support returning transaction status."), $outputFormat)

    else common:error("corona:UNSUPPORTED-METHOD", concat("Unsupported method: ", $requestMethod), $outputFormat)
