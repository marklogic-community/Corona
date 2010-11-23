xquery version "1.0-ml";

module namespace temp="http://marklogic.com/twitter/template";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";

declare function temp:template(
    $content as element()*,
    $page as xs:string
) as item()+
{
    let $set := xdmp:set-response-content-type("text/html")
    return (
        "<!DOCTYPE html>", 
        <html>
            <head>
                <link type="text/css" href="css/ui-lightness/jquery-ui-1.8.6.custom.css" rel="stylesheet" />    
                <link rel="stylesheet" href="css/template.css" type="text/css" />
                <link rel="stylesheet" href="css/{ $page }.css" type="text/css" />
                <title>JSON Storage</title>
            </head>
            <body>
                <div id="wrap">
                    <div id="header">			
                        <h1 id="logo-text"><a href="index.xqy">JSON Storage</a></h1>		
                        <p id="slogan">Using MarkLogic as a JSON store</p>
                        <div id="header-links"><p>
                            <!-- <a href="index.html">Home</a> | 
                            <a href="index.html">Contact</a> | 
                            <a href="index.html">Site Map</a> -->
                        </p></div>		
                    </div>
                    <div id="menu">
                        <ul>
                            <li>{ if($page = "search") then attribute id {"current"} else () }<a href="index.xqy">Search</a></li>
                            <li class="last">{ if($page = "fetch") then attribute id {"current"} else () }<a href="fetch.xqy">Fetch and Store</a></li>
                        </ul>
                    </div>
                    <div id="content-wrap">
                        <div id="main">{ $content }</div>
                    </div>
                    <div id="footer">&nbsp;</div>	
                </div>
                <script type="text/javascript" src="js/jquery-1.4.3.min.js">&nbsp;</script>
                <script type="text/javascript" src="js/jquery-ui-1.8.6.custom.min.js">&nbsp;</script>
                <script type="text/javascript" src="js/{ $page }.js">&nbsp;</script>
                <script type="text/javascript" src="js/util.js">&nbsp;</script>
            </body>
        </html>
    )
};

