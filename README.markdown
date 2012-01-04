# Corona - A REST interface to MarkLogic

The Corona project is a community-sponsored set of REST endpoints that enable usage of  [MarkLogic Server](http://developer.marklogic.com) without knowledge of XQuery.

Corona provides endpoints for storing, searching and transforming XML, JSON, text and binary documents.

Inside each of the REST endpoints exists a number of other powerful features. For example, the entire structure of the documents can be queried with either key/value lookups, a search box query string, or a powerful structured query language. When retrieving documents, a path may be provided to extract out specific sections and XSLT/XQuery transformations can be applied to the content.

Specific to JSON content, dates in dozens of formats can be parsed and stored as actual dates. If the value of a key is a string of XML, that XML can be unquoted, stored and queried as actual XML.

On top of this, you get the built in scalability, speed and database features that MarkLogic Server provides. Need geospatial support? It's included. Clustering? Yep, that's there too. Multiple languages? Of course! Powerful fulltext search? Nobody does it better.

There is a tutorial at http://developer.marklogic.com/try/corona/index

Corona runs on MarkLogic 4.1 or later.  Some features require 4.2 or 5.0.

## [Installation](https://github.com/marklogic/Corona/wiki/Installation)

## [API Documentation](http://github.com/marklogic/Corona/wiki)
[Check the wiki for documentation on how to store, index and query the documents.](http://github.com/marklogic/Corona/wiki)

## Get Involved
There is a mailing list for Corona users at http://developer.marklogic.com/mailman/listinfo/corona