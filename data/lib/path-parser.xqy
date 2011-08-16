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

module namespace path="http://marklogic.com/mljson/path-parser";

import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";


declare function path:select(
    $doc as element(),
    $path as xs:string
) as element()*
{
    if(string-length($path) = 0)
    then $doc
    else
        let $tokens := path:tokenize($path)
        for $part in $doc/xdmp:value(path:constructPath($tokens))
        return
            if(namespace-uri($part) = "http://marklogic.com/json")
            then <json:item>{ $part/(@*, node()) }</json:item>
            else $part
};

declare function path:parse(
    $path as xs:string
) as xs:string
{
    let $tokens := path:tokenize($path)
    return path:constructPath($tokens)
};

declare private function path:tokenize(
    $path as xs:string
) as element()*
{

    let $tokens := (
        '\[("[^"]*)"\]',
        '\[(\d+)\]',
        "([a-zA-Z_$][0-9a-zA-Z_$]*)", 

        '(root\(\))',
        '(parent\(\))',
        'ancestor\("([^"]*)"\)',
        'xpath\("([^"]*)"\)',
        "(\.)",
        "(\*)",

        "(\s+)"
    )

    let $regex := string-join(for $token in $tokens return $token, "|")
    for $match in analyze-string($path, $regex)/*
    return
        if($match/self::*:non-match) then <error>{ string($match) }</error>
        else if($match/*:group/@nr = 1) then <step origin="bracketed" type="key">{ replace(string($match/*:group), '"', "") }</step>
        else if($match/*:group/@nr = 2) then <step type="index">{ replace(string($match/*:group), '"', "") }</step>
        else if($match/*:group/@nr = 3) then <step type="key">{ string($match) }</step>

        else if($match/*:group/@nr = 4) then <root>{ string($match) }</root>
        else if($match/*:group/@nr = 5) then <parent>{ string($match) }</parent>
        else if($match/*:group/@nr = 6) then <ancestor>{ string($match/*:group) }</ancestor>
        else if($match/*:group/@nr = 7) then <xpath>{ string($match/*:group) }</xpath>
        else if($match/*:group/@nr = 8) then <dot>{ string($match) }</dot>
        else if($match/*:group/@nr = 9) then <wildstep>{ string($match) }</wildstep>

        else if($match/*:group/@nr = 10) then ()

        else xdmp:log(concat("Unknown group in path parsing: ", xdmp:quote($match)))
};

declare private function path:constructPath(
    $tokens as element()+
) as xs:string
{
    string-join(
        for $token at $index in $tokens
        return
            typeswitch($token)
            case element(step) return path:processStep($tokens, $index)
            case element(root) return path:processRoot($tokens, $index)
            case element(parent) return path:processParent($tokens, $index)
            case element(ancestor) return path:processAncestor($tokens, $index)
            case element(xpath) return path:processXPath($tokens, $index)
            case element(wildstep) return path:processWildstep($tokens, $index)
            case element(dot) return path:processDot($tokens, $index)

            case element(error) return path:processError($tokens, $index)
            default return path:throwError($tokens, $index, "This is a bug! Unhandled token: xdmp:quote($token)")
    , "/")
};

declare private function path:processStep(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot" or (local-name($nextToken) = "step" and ($nextToken/@origin = "bracketed" or $nextToken/@type = "index")))
        then ()
        else path:throwError($tokens, $index + 1, "expected either a dot, a quoted step or an array index")
    let $step := $tokens[$index]
    return
        if($step/@type = "index")
        then concat("json:item[", string($step), "]")
        else if($step/@type = "key")
        then concat("json:", json:escapeNCName(string($step)))
        else ()
};

declare private function path:processRoot(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot" or (local-name($nextToken) = "step" and ($nextToken/@origin = "bracketed" or $nextToken/@type = "index")))
        then ()
        else path:throwError($tokens, $index + 1, "expected either a dot, a quoted step or an array index")
    return "ancestor-or-self::json:json"
};

declare private function path:processParent(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot" or (local-name($nextToken) = "step" and ($nextToken/@origin = "bracketed" or $nextToken/@type = "index")))
        then ()
        else path:throwError($tokens, $index + 1, "expected either a dot, a quoted step or an array index")
    return ".."
};

declare private function path:processAncestor(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot" or (local-name($nextToken) = "step" and ($nextToken/@origin = "bracketed" or $nextToken/@type = "index")))
        then ()
        else path:throwError($tokens, $index + 1, "expected either a dot, a quoted step or an array index")
    return concat("ancestor::json:", json:unescapeNCName(string($tokens[$index])))
};

declare private function path:processXPath(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(exists($nextToken))
        then path:throwError($tokens, $index + 1, "expected not to see any more tokens after the XPath")
        else ()
    let $XPath  := string($tokens[$index])
    let $XPath :=
        if(starts-with($XPath, "/"))
        then substring($XPath, 2)
        else $XPath
    return $XPath
};

declare private function path:processWildstep(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot" or (local-name($nextToken) = "step" and ($nextToken/@origin = "bracketed" or $nextToken/@type = "index")))
        then ()
        else path:throwError($tokens, $index + 1, "expected either a dot, a quoted step or an array index")
    return
        if(count($tokens) = $index)
        then "*"
        else if($index = 1)
        then "/"
        else ""
};

declare private function path:processDot(
    $tokens as element()*,
    $index as xs:integer
) as xs:string?
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "dot")
        then path:throwError($tokens, $index + 1, "expected either a step or a function call")
        else ()

    return
        if($index = 1)
        then "ancestor-or-self::json:json"
        else ()
};


declare private function path:generateContext(
    $tokens as element()*,
    $errorIndex as xs:integer
) as xs:string
{
    string-join(
        let $surrounding := $tokens[$errorIndex - 3 to $errorIndex + 3]
        for $token in $surrounding
        return
            typeswitch($token)
            case element(step) return 
                if($token/@type = "index")
                then concat("[", string($token), "]")
                else if($token/@origin = "bracketed")
                then concat('["', string($token), '"]')
                else string($token)
            case element(root) return "root()"
            case element(parent) return "parent()"
            case element(ancestor) return concat('ancestor("', string($token), '")')
            case element(wildstep) return "*"
            case element(dot) return "."

            case element(error) return string($token)
            default return ()
    , "")
};

declare private function path:processError(
    $tokens as element()*,
    $errorIndex as xs:integer
) as empty-sequence()
{
    let $context := path:generateContext($tokens, $errorIndex)
    return error(xs:QName("path:UNEXPECTED"), concat("Unexpected token '", string($tokens[$errorIndex]), "' in path '", $context, "'"))
};

declare private function path:throwError(
    $tokens as element()*,
    $errorIndex as xs:integer,
    $message as xs:string
) as empty-sequence()
{
    let $context := path:generateContext($tokens, $errorIndex)
    return error(xs:QName("path:UNEXPECTED"), concat("Unexpected token '", string($tokens[$errorIndex]), "' in path '", $context, "', ", $message, "."))
};
