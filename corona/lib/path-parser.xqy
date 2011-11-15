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
import module namespace as="http://marklogic.com/corona/analyze-string" at "analyze-string.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $analyzeString := try { xdmp:function(xs:QName("fn:analyze-string")) } catch ($e) {};
declare variable $regexSupported := try { exists(xdmp:apply($analyzeString, " ", " ")) } catch ($e) { false() };

declare function path:supportedFormats(
) as xs:string*
{
    if($regexSupported)
    then "json"
    else (),
    "xpath"
};

declare function path:select(
    $doc as node(),
    $path as xs:string,
    $type as xs:string
) as node()*
{
    if(not($type = path:supportedFormats()))
    then error(xs:QName("path:INVALID-TYPE"), concat("Invalid type: '", $type, "'."))
    else if(string-length($path) = 0)
    then $doc
    else
        let $tokens := path:tokenize($path, $type)
        for $part in $doc/xdmp:value(path:constructPath($tokens, $type))
        return
            if(namespace-uri($part) = "http://marklogic.com/json")
            then <json:item>{ $part/(@*, node()) }</json:item>
            else $part
};

declare function path:parse(
    $path as xs:string,
    $type as xs:string
) as xs:string
{
    let $tokens := path:tokenize($path, $type)
    return path:constructPath($tokens, $type)
};

declare private function path:tokenize(
    $path as xs:string,
    $type as xs:string
) as element()*
{
    if($type = "json")
    then
        let $tokens := (
                '\[("[^"]*)"\]',
                '\[(\d+)\]',
                '([a-zA-Z_$][0-9a-zA-Z_$]*)',

                '(root\(\))',
                '(parent\(\))',
                'ancestor\("([^"]*)"\)',
                'xpath\("([^"]*)"\)',
                '(\.)',
                '(\*)',

                '(\s+)'
            )

        let $regex := string-join(for $token in $tokens return $token, "|")
        for $match in xdmp:apply($analyzeString, $path, $regex)/*
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
    else
        let $tokens := (
            '(ancestor::\i\c*)',
            '(ancestor\-or\-self::\i\c*)',
            '(attribute::\i\c*)',
            '(@\i\c*)',
            '(child::\i\c*)',
            '(descendant::\i\c*)',
            '(//\i\c*)',
            '(descendant\-or\-self::\i\c*)',
            '(following::\i\c*)',
            '(following-sibling::\i\c*)',
            '(namespace::\i\c*)',
            '(parent::\i\c*)',
            '(\.\.)',
            '(preceding::\i\c*)',
            '(preceding\-sibling::\i\c*)',
            '(self::\i\c*)',
            '(\i\c*)',
            '(/)',
            '(\*)',
            '\[(\d+)\]'
        )

        for $match in as:analyzeString($path, $tokens)/*
        return
            if($match/self::*:non-match) then <error>{ string($match) }</error>
            else if($match/*:group/@nr = 1) then <axis type="ancestor" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 2) then <axis type="ancestor-or-self" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 3) then <axis type="attribute" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 4) then <axis type="attribute" axis="false">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 5) then <axis type="child" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 6) then <axis type="descendant" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 7) then (<slash>/</slash>, <axis type="descendant" axis="false">{ string($match/*:group) }</axis>)
            else if($match/*:group/@nr = 8) then <axis type="descendant-or-self" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 9) then <axis type="following" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 10) then <axis type="following-sibling" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 11) then <axis type="namespace" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 12) then <axis type="parent" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 13) then <axis type="parent" axis="false">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 14) then <axis type="preceding" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 15) then <axis type="preceding-sibling" axis="true">{ string($match/*:group) }</axis>
            else if($match/*:group/@nr = 16) then <axis type="self" axis="true">{ string($match/*:group) }</axis>

            else if($match/*:group/@nr = 17) then <element>{ string($match) }</element>
            else if($match/*:group/@nr = 18) then <slash>{ string($match) }</slash>
            else if($match/*:group/@nr = 19) then <wildstep>{ string($match) }</wildstep>
            else if($match/*:group/@nr = 20) then <predicate>[{ string($match/*:group) }]</predicate>

            else xdmp:log(concat("Unknown group in xpath parsing: ", xdmp:quote($match)))
};

declare private function path:constructPath(
    $tokens as element()+,
    $type as xs:string
) as xs:string
{
        if($type = "json")
        then string-join(
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
                default return path:throwError($tokens, $index, concat("This is a bug! Unhandled token:", xdmp:quote($token)))
        , "/")
        else string-join(
            for $token at $index in $tokens
            return
                typeswitch($token)
                case element(axis) return path:processXPathAxis($tokens, $index)
                case element(element) return path:processXPathElement($tokens, $index)
                case element(wildstep) return path:processXPathWildstep($tokens, $index)
                case element(predicate) return path:processXPathPredicate($tokens, $index)
                case element(slash) return path:processXPathSlash($tokens, $index)

                case element(error) return path:processError($tokens, $index)
                default return path:throwError($tokens, $index, concat("This is a bug! Unhandled token:", xdmp:quote($token)))
        , "")
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
        then concat("json:item[", xs:integer($step) + 1, "]")
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
    return path:parse($XPath, "xml")
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


declare private function path:processXPathAxis(
    $tokens as element()*,
    $index as xs:integer
) as xs:string?
{
    let $token := $tokens[$index]
    let $value := string($token)
    let $elementName :=
        if($token/@axis = "true")
        then substring-after($value, "::")
        else if($token/@type = "attribute")
        then substring($value, 2)
        else if($token/@type = "descendant")
        then substring($value, 3)
        else if($token/@type = "parent")
        then ()
        else $value
    let $test :=
        if(exists($elementName))
        then try {
                xs:QName($elementName)[2]
            }
            catch ($e) {
                error(xs:QName("path:INVALID-XML-ELEMENT-NAME"), concat("Invalid XML element name or undefined namespace prefix: '", $elementName, "'."))
            }
        else ()

    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "slash" or local-name($nextToken) = "predicate")
        then ()
        else path:throwError($tokens, $index + 1, "expected either a slash or a predicate")
    let $test :=
        if($token/@type = "attribute" and exists($nextToken))
        then path:throwError($tokens, $index + 1, "cannot descend into attribute values")
        else ()

    return
        if($token/@type = "descendant" and starts-with($value, "//"))
        then substring($value, 2)
        else $value
};

declare private function path:processXPathElement(
    $tokens as element()*,
    $index as xs:integer
) as xs:string?
{
    let $nextToken := $tokens[$index + 1]
    let $value := string($tokens[$index])
    let $test := try {
            xs:QName($value)[2]
        }
        catch ($e) {
            error(xs:QName("path:INVALID-XML-ELEMENT-NAME"), concat("Invalid XML element name or undefined namespace prefix: '", $value, "'."))
        }
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "slash" or local-name($nextToken) = "predicate")
        then ()
        else path:throwError($tokens, $index + 1, "expected either a slash or a predicate")
    return $value
};

declare private function path:processXPathWildstep(
    $tokens as element()*,
    $index as xs:integer
) as xs:string?
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "slash" or local-name($nextToken) = "predicate")
        then ()
        else path:throwError($tokens, $index + 1, "expected either a slash or a predicate")
    return string($tokens[$index])
};

declare private function path:processXPathPredicate(
    $tokens as element()*,
    $index as xs:integer
) as xs:string?
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "slash")
        then ()
        else path:throwError($tokens, $index + 1, "expected a slash")
    return string($tokens[$index])
};

declare private function path:processXPathSlash(
    $tokens as element()*,
    $index as xs:integer
) as xs:string
{
    let $nextToken := $tokens[$index + 1]
    let $test :=
        if(empty($nextToken) or local-name($nextToken) = "slash" or local-name($nextToken) = "predicate")
        then path:throwError($tokens, $index + 1, "expected either an XML element or an XPath axis")
        else ()
    return "/"
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

            case element(axis) return string($token)
            case element(element) return string($token)
            case element(slash) return "/"
            case element(predicate) return string($token)

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
