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

module namespace stringquery = "http://marklogic.com/corona/string-query";

import module namespace config="http://marklogic.com/corona/index-config" at "index-config.xqy";
import module namespace as="http://marklogic.com/corona/analyze-string" at "analyze-string.xqy";
import module namespace common="http://marklogic.com/corona/common" at "common.xqy";
import module namespace search="http://marklogic.com/corona/search" at "search.xqy";
import module namespace json="http://marklogic.com/json" at "json.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare private variable $GROUPING-INDEX as xs:integer := 0;


declare function stringquery:parse(
	$query as xs:string?
) as cts:query?
{
    stringquery:parse($query, (), true())
};

declare function stringquery:parse(
	$query as xs:string?,
    $ignoreField as xs:string?
) as cts:query?
{
    stringquery:parse($query, $ignoreField, true())
};

declare function stringquery:parse(
	$query as xs:string?,
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
	let $init := xdmp:set($GROUPING-INDEX, 0)
	let $tokens := stringquery:tokenize($query)
	let $grouped := stringquery:groupTokens($tokens, 1)
	let $folded := stringquery:foldTokens(<group>{ $grouped }</group>, ("not", "or", "and", "near"))
    where string-length($query)
	return stringquery:dispatchQueryTree($folded, $ignoreField, $useRQ)
};

declare function stringquery:getParseTree(
    $query as xs:string
) as element(group)
{
	let $init := xdmp:set($GROUPING-INDEX, 0)
	let $tokens := stringquery:tokenize($query)
	let $grouped := stringquery:groupTokens($tokens, 1)
	return stringquery:foldTokens(<group>{ $grouped }</group>, ("not", "or", "and", "near"))
};

declare function stringquery:getCTSFromParseTree(
    $parseTree as element(group)
) as cts:query?
{
    stringquery:getCTSFromParseTree($parseTree, (), true())
};

declare function stringquery:getCTSFromParseTree(
    $parseTree as element(group),
    $ignoreField as xs:string?
) as cts:query?
{
    stringquery:getCTSFromParseTree($parseTree, $ignoreField, true())
};

declare function stringquery:getCTSFromParseTree(
    $parseTree as element(group),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
	stringquery:dispatchQueryTree($parseTree, $ignoreField, $useRQ)
};

declare function stringquery:containsNamedQuery(
	$query as xs:string?
) as xs:boolean
{
    exists(
        let $tree := stringquery:getParseTree($query)
        for $term in $tree//constraint
        let $index := config:get($term/field)
        where $index[@type = "namedQueryPrefix"]
        return true()
    )
};


declare function stringquery:valuesForFacet(
    $parseTree as element(group),
    $facetName as xs:string
) as xs:string*
{
    for $constraint in $parseTree//constraint[field = $facetName]
    return string($constraint/value)
};

declare private function stringquery:tokenize(
	$query as xs:string
) as element()*
{
	let $phraseMatch := '"[^"]+"'
	let $wordMatch := "[\w,\._\*\?][\w\._\-,\*\?:]*"
	let $constraintMatch := "[A-Za-z0-9_\-]+:"
	let $tokens := (
		"\(", "\)", $phraseMatch,
		"\-", " AND ", " OR ", " NEAR ", " NEAR/\d+ ",
		concat($constraintMatch, $phraseMatch, "|", $constraintMatch, "\-?", $wordMatch),
		$wordMatch, "\s+"
	)

    let $tokens := for $token in $tokens return concat("(", $token, ")")
	for $match in as:analyzeString($query, $tokens)/*
	return
		if($match/self::*:non-match) then <error>{ string($match) }</error>
		else if($match/*:group/@nr = 1) then <startgroup/>
		else if($match/*:group/@nr = 2) then <endgroup/>
		else if($match/*:group/@nr = 3) then <phrase>{
				let $value := string($match)
				return substring($value, 2, string-length($value) - 2)
			}</phrase>
		else if($match/*:group/@nr = 4) then <not/>
		else if($match/*:group/@nr = 5) then <and/>
		else if($match/*:group/@nr = 6) then <or/>
		else if($match/*:group/@nr = 7) then <near distance="10"/>
		else if($match/*:group/@nr = 8) then <near distance="{ xs:double(tokenize(string($match), "/")[2]) }"/>
		else if($match/*:group/@nr = 9) then <constraint>{
				let $bits := tokenize($match, ":")
				return (
					<field>{ $bits[1] }</field>,
					<value>{ replace(string-join($bits[2 to last()], ":"), '^"|"$', "") }</value>
				)
			}</constraint>
		else if($match/*:group/@nr = 10) then <term>{ string($match) }</term>
		else if($match/*:group/@nr = 11) then <whitespace>{ string($match) }</whitespace>

		else <error>{ string($match) }</error>
};

declare private function stringquery:groupTokens(
	$tokens as element()*,
	$starting-index as xs:integer
) as element()*
{
	let $continue := true()
	for $token at $index in $tokens[$starting-index to count($tokens)]
	let $index := $starting-index + $index - 1
	where $continue and $index > $GROUPING-INDEX
	return (
		xdmp:set($GROUPING-INDEX, $GROUPING-INDEX + 1)
		,
		if(local-name($token) = "startgroup")
		then <group>{ stringquery:groupTokens($tokens, $index + 1) }</group>
		else if(local-name($token) = "endgroup")
		then
			if($starting-index > 1)
			then xdmp:set($continue, false())
			else ()
        else if(local-name($token) = "constraint")
        then
            let $indexConfig := config:get($token/field)
            return
                if(exists($indexConfig[type = ("date", "dateTime")]))
                then 
                    <constraint>{ $token/field }<value>{(
                        let $parsedDate := ()
                        for $dateToken at $dateIndex in $tokens[$index to count($tokens)]
                        where local-name($dateToken) = ("term", "constraint") and empty($parsedDate)
                        return
                            let $possibleTokens :=
                                for $i in $tokens[$index + 1 to $dateIndex + $index]
                                return
                                    if(local-name($i) = "term")
                                    then string($i)
                                    else if(local-name($i) = "constraint")
                                    then concat($i/field, ":", $i/value)
                                    else ()
                            let $dateString := string-join(($token/value, $possibleTokens), " ")
                            let $date := common:castFromJSONType($dateString, "date")
                            return
                                if(exists($date))
                                then ($date, xdmp:set($parsedDate, $date), xdmp:set($GROUPING-INDEX, $index + $dateIndex - 1))
                                else ()
                        ,
                        string($token/value)
                    )[1]}</value></constraint>
                else if(exists($indexConfig[@type = "geo"]))
                then 
                    <constraint>{ $token/field }<value>{
                        if(count(tokenize($token/value, "\.")) > 2)
                        then string($token/value)
                        else if(local-name($tokens[$index + 1]) = "whitespace" and local-name($tokens[$index + 2]) = "term")
                        then (
                            concat($token/value, " ", $tokens[$index + 2]),
                            xdmp:set($GROUPING-INDEX, $index + 2)
                        )
                        else if(local-name($tokens[$index + 1]) = "whitespace" and local-name($tokens[$index + 2]) = "not" and local-name($tokens[$index + 3]) = "term")
                        then (
                            concat($token/value, " -", $tokens[$index + 3]),
                            xdmp:set($GROUPING-INDEX, $index + 3)
                        )
                        else string($token/value)
                    }</value></constraint>
                else $token
		else $token
	)
};

declare private function stringquery:foldTokens(
	$group as element(group),
	$order as xs:string*
) as element(group)
{
	let $order :=
		for $operator in $order
		where exists($group//*[local-name(.) = $operator])
		return $operator
	let $newGroup :=
		<group>{
			let $nextIndex := 1
			let $foundOne := false()
			let $tokens := $group/*
			for $token at $index in $tokens
			let $nextName := local-name($tokens[$index + 1])
			where $index = $nextIndex
			return (
				xdmp:set($nextIndex, $nextIndex + 1),

				if($order[1] = "and" and $nextName = "and" and $foundOne = false())
				then (
					stringquery:extractSequence($tokens, "and", $index, $order),
					xdmp:set($foundOne, true()),
					xdmp:set($nextIndex, $index + 3)
				)
				else if($order[1] = "or" and $nextName = "or" and $foundOne = false())
				then (
					stringquery:extractSequence($tokens, "or", $index, $order),
					xdmp:set($foundOne, true()),
					xdmp:set($nextIndex, $index + 3)
				)
				else if($order[1] = "not" and local-name($token) = "not" and $foundOne = false())
				then (
					<notQuery>{ stringquery:foldIfNeeded($tokens[$index + 1], $order) }</notQuery>,
					xdmp:set($foundOne, true()),
					xdmp:set($nextIndex, $index + 2)
				)
				else if($order[1] = "near" and $nextName = "near" and $foundOne = false())
				then (
					stringquery:extractSequence($tokens, "near", $index, $order),
					xdmp:set($foundOne, true()),
					xdmp:set($nextIndex, $index + 3)
				)
				else if(local-name($token) = "group")
				then stringquery:foldTokens($token, $order)
				else $token
			)
		}</group>
	return
		if(exists($newGroup//(and, or, not, near)))
		then stringquery:foldTokens($newGroup, $order)
		else $newGroup
};

declare private function stringquery:foldIfNeeded(
	$token as element(),
	$order as xs:string*
) as element()
{
	if(local-name($token) = "group")
	then stringquery:foldTokens($token, $order)
	else $token
};

declare private function stringquery:extractSequence(
	$tokens as element()*,
	$operator as xs:string,
	$index as xs:integer,
	$order as xs:string*
) as element()
{
	element { concat($operator, "Query") } {(
		if(local-name($tokens[$index]) = concat($operator, "Query"))
		then ($tokens[$index]/@*, $tokens[$index]/*)
		else ($tokens[$index + 1]/@*, stringquery:foldIfNeeded($tokens[$index], $order))
		,
		stringquery:foldIfNeeded($tokens[$index + 2], $order)
	)}
};


declare private function stringquery:dispatchQueryTree(
	$token as element(),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:query*
{
	let $queries :=
		for $term in $token/*
		return stringquery:termToQuery($term, $ignoreField, $useRQ)
	return
		if(count($queries) = 1 or local-name($token) = ("andQuery", "orQuery"))
		then $queries
		else cts:and-query($queries)
};

declare private function stringquery:termToQuery(
	$term as element(),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
	typeswitch ($term)
	case element(andQuery) return cts:and-query(stringquery:dispatchQueryTree($term, $ignoreField, $useRQ))
	case element(orQuery) return cts:or-query(stringquery:dispatchQueryTree($term, $ignoreField, $useRQ))
	case element(notQuery) return stringquery:notQuery($term, $ignoreField, $useRQ)
	case element(nearQuery) return stringquery:nearQuery($term, $ignoreField, $useRQ)
	case element(constraint) return stringquery:constraintQuery($term, $ignoreField, $useRQ)
	case element(term) return stringquery:wordQuery($term)
	case element(phrase) return stringquery:wordQuery($term)
	case element(group) return stringquery:dispatchQueryTree($term, $ignoreField, $useRQ)
	case element(whitespace) return ()

	default return xdmp:log(concat("Unhandled query token: ", xdmp:quote($term)))
};

declare private function stringquery:wordQuery(
	$term as element()
) as cts:query
{
    let $index := config:getPlace(())
    let $query := search:placeValueToQuery($index, string($term))
    return
        if(empty($query))
        then cts:word-query(string($term))
        else $query
};

declare private function stringquery:notQuery(
	$term as element(notQuery),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:not-query
{
	cts:not-query(stringquery:dispatchQueryTree($term, $ignoreField, $useRQ))
};

declare private function stringquery:nearQuery(
	$term as element(nearQuery),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:near-query
{
	cts:near-query(stringquery:dispatchQueryTree($term, $ignoreField, $useRQ), $term/@distance)
};

declare private function stringquery:constraintQuery(
	$term as element(constraint),
    $ignoreField as xs:string?,
    $useRQ as xs:boolean
) as cts:query?
{
    let $value := string($term/value)
    let $index := config:get($term/field)
    where if(exists($ignoreField)) then string($term/field) != $ignoreField else true()
    return
        if($index/@type = "place")
        then search:placeValueToQuery($index, $value)

        else if($index/@type = "range")
        then search:rangeValueToQuery($index, $value, (string($index/operator), "eq")[1], ())

        else if($index/@type = ("bucketedrange", "autobucketedrange"))
        then search:bucketLabelToQuery($index, $value)

        else if($index[@type = "namedQueryPrefix"])
        then search:getStoredQueryCTS(concat($term/field, ":", $value), $ignoreField, $useRQ)

        else if($index/@type = "geo")
        then
            let $bits := for $i in tokenize(normalize-space($value), "[^\d\-\+\.]") where string-length($i) return $i
            let $latitude := xs:float($bits[1])
            let $longitude := xs:float($bits[2])
            return search:geoQuery($index, cts:circle(10, cts:point($latitude, $longitude)), (), ())
        else stringquery:wordQuery(<term>{ concat($term/field, ":", $value) }</term>)
};

declare private function stringquery:treeToString(
	$tree as element()
) as xs:string
{
	typeswitch ($tree)
	case element(andQuery) return string-join(for $i in $tree/* return stringquery:treeToString($i), " AND ")
	case element(orQuery) return string-join(for $i in $tree/* return stringquery:treeToString($i), " OR ")
	case element(notQuery) return concat("-", stringquery:treeToString($tree/*[1]))
	case element(nearQuery) return
		let $near := if(exists($tree/@distance)) then concat(" NEAR/", $tree/@distance, " ") else " NEAR "
		return string-join(for $i in $tree/* return stringquery:treeToString($i), $near)
	case element(constraint) return concat($tree/field, ":", $tree/value)
	case element(term) return string($tree)
	case element(phrase) return concat('"', string($tree), '"')
	case element(group) return concat("(", for $i in $tree/* return stringquery:treeToString($i), ")")
	case element(whitespace) return " "

	default return xdmp:log(concat("Unhandled token: ", xdmp:quote($tree)))
};
