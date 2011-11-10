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

module namespace as="http://marklogic.com/corona/analyze-string";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function as:analyzeString(
    $input as xs:string,
    $tokens as xs:string+
) as element()
{
    try {
        xdmp:apply(xdmp:function(xs:QName("fn:analyze-string")), $input, as:generateRegex($tokens))
    }
    catch ($e ) {
        as:manualMatch($input, $tokens)
    }
};

declare private function as:generateRegex(
    $tokens as xs:string+
) as xs:string
{
    string-join($tokens, "|")
};

declare private function as:manualMatch(
    $input as xs:string,
    $tokens as xs:string+
) as element()
{
    let $regex := as:generateRegex($tokens)
    let $replacement := string-join(for $i in 1 to count($tokens) return concat("[", $i, ":$", $i, "]"), "") 
    let $temp := replace($input, $regex, $replacement)
    let $temp := replace($temp, "\[\d\d?:\]", "")
    let $resultXML := xdmp:unquote(concat("<foo>", replace($temp, "\[(\d\d?):([^\[]*)\]", "<match><group nr='$1'>$2</group></match>"), "</foo>"))/*
    return <analyze-string-result xmlns='http://www.w3.org/2009/xpath-functions/analyze-string'>{
        for $node in $resultXML/node()
        return
            if($node instance of element())
            then $node
            else <non-match>{ $node }</non-match>
    }</analyze-string-result>
};
