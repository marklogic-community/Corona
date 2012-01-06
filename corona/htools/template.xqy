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

module namespace template="http://marklogic.com/corona/template";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function template:apply(
		$content as element()*,
        $title as xs:string,
        $nav as element(li)*,
        $page as xs:integer,
        $scripts as element(script)*
) as item()+
{
    template:apply($content, $title, $nav, $page, $scripts, ())
};

declare function template:apply(
		$content as element()*,
        $title as xs:string,
        $nav as element(li)*,
        $page as xs:integer,
        $scripts as element(script)*,
        $links as element(link)*
) as item()+
{
	let $set := xdmp:set-response-content-type("text/html; charset=utf-8")
    (: 
    let $nav := (
        <li><h4><a href="./index.xqy">Getting Started</a></h4></li>,
        <li><h4><a href="./page2.xqy">Lay of the Land</a></h4></li>,
        <li><h4><a href="./page3.xqy">Looking at a Mail Message</a></h4></li>,
        <li><h4><a href="./page4.xqy">Drilling in with XPath</a></h4></li>,
        <li><h4><a href="./page5.xqy">Formatting Results</a></h4></li>,
        <li><h4><a href="./page6.xqy">Constraints</a></h4></li>,
        <li><h4><a href="./page7.xqy">Facets</a></h4></li>,
        <li><h4><a href="./page8.xqy">Text Search</a></h4></li>,
        <li><h4><a href="./page9.xqy">Search Relevance</a></h4></li>,
        <li><h4><a href="./page10.xqy">Functions</a></h4></li>,
        <li><h4><a href="./page11.xqy">Query-Limited Facets</a></h4></li>,
        <li><h4><a href="./page12.xqy">The Search API</a></h4></li>,
        <li><h4><a href="./page13.xqy">Extending Search API</a></h4></li>,
        <li><h4><a href="./page14.xqy">Conclusion</a></h4></li>
    )
    :)
	return (
"<!DOCTYPE html>",
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <title>{ $title } - Corona</title>
        <!--[if IE]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
        <style>
            article, aside, dialog, figure, footer, header, hgroup, menu, nav, section {{ display: block; }}
        </style>

        <link rel="stylesheet" href="/corona/htools/css/screen.css" type="text/css" media="screen, projection" />
        <link rel="stylesheet" href="/corona/htools/css/print.css" type="text/css" media="print"/>
        <!--[if lt IE 8]><link rel="stylesheet" href="/corona/htools/css/ie.css" type="text/css" media="screen, projection"/><![endif]-->
        { $links }
    </head>
    <body>
        <div class="header">
            <div class="top_bar">
                <div class="container">
                    <img alt="MarkLogic" src="/corona/htools/img/ml_logo.png"/>
                </div>
            </div>
        </div>

        <div class="main">
            <div class="container">
                {
                if(exists($nav))
                then
                    <div class="aside">
                        <ul class="subnav">{
                            for $navItem at $pos in $nav
                            return <li>{(
                                if($pos = $page)
                                then attribute class {"subnav_item_active"}
                                else (),
                                $navItem/*
                            )}</li>
                        }</ul>
                    </div>
                else ()
                }
                <div class="content">{ $content }</div>
            </div>
        </div>

        <div class="footer">
            <div class="container">
                <p>Copyright © 2010-2011 MarkLogic Corporation. All rights reserved.</p>
            </div>
        </div>
    </body>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"><!-- --></script>
    { $scripts }
</html>
)
};
