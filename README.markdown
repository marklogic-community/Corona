# MLJSON - A JSON Facade on top of MarkLogic

The MLJSON project is a set of libraries and REST endpoints to enable the [MarkLogic Server] to become an advanced [JSON] store.

#### MarkLogic  ####
 - High-performance, scalable database for unstructured information
 - "NoSQL" datastore (no tables, rows, columns) - just documents and unique IDs (URIs).
 - Uses XML datamodel for documents, query-able via XQuery, XSLT, XPath
 - Uses search-engine techniques to efficiently expose real-time fulltext search 
 - ACID-compliant CRUD (Create, Read, Update, Delete)

#### JSON ####
  - JavaScript Object Notation
  - A lightweight data-encoding and interchange format
  - Native to JavaScript, now widely utilized across languages
  - Commonly used for passing data to web browsers

#### Design goal
Enable developers to store and search/query JSON inside MarkLogic (without knowledge of XQuery, XSLT, or XPath)

#### Design considerations: 
1. Approach things from a JSON angle
- Create the XML to match the JSON, not vice-versa 
2. Make good use of MarkLogic indexes
- Craft the XML so it's fast to query
3. XML representation of JSON is an implementation detail - users only need think in terms of JSON

#### Overview
MLJSON exposes REST endpoints that allow a developer to
easily store and retrieve JSON documents from the database ([CRUD]).  It also
exposes a very powerful query interface that uses a native JSON syntax:

Query using native JSON syntax 
- Don't expose the XML internals to users 
- Support full range of MarkLogic indexes

This query interface allows the user to find documents via "path" expressions as
well as full text search expressions.  For those familiar with MarkLogic, it
exposes all of the functionality found in the [CTS search functions].

#### Presentation
Here are some [slides] from a presentation on MLJSON given at XML Prague 2011.

___

## Installation

Installing MLJSON is fairly simple:

1. If you don't have a HTTP server configured in MarkLogic, create one
2. Set the URL rewriter for the HTTP server to: /data/lib/rewriter.xqy
3. Download the MLJSON source and unzip it underneath the document directory that you configured in the MarkLogic HTTP server

Feel free to remove the README and LICENSE files along with the test directory.
But keep the config and data directories structured as they are. You can
augment the functionality of MLJSON by writing your own XQuery and having it
live alongside the MLJSON files.

The URL rewritter is configured in the config/endpoints.xqy file. You can
change the URL structure or add in more rules if need be there.

### Files relevant to the end user
 - data/lib/rewriter.xqy - A URL rewriter for the REST calls
 - config/endpoints.xqy - Configuration for the REST endpoints
 - data/lib/json.xqy - Library module for handling JSON, see comments inside file for details on each function
   - jsonToXML - parses a JSON string into XML that can be stored in MarkLogic
   - xmlToJSON - parses the generated XML into a JSON string
   - document - constructs a JSON document
   - object - constructs a JSON object
   - array - constructs a JSON array
   - null - constructs a JSON null
 - data/lib/json-query.xqy - Tinkering with ways to query the stored JSON

## Documentation
[Check the wiki for documentation on how to store, index and query the documents.](mljson/wiki)

  [MarkLogic]: http://developer.marklogic.com
  [MarkLogic Server]: http://developer.marklogic.com
  [CRUD]: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete
  [CTS search functions]: http://developer.marklogic.com/pubs/4.2/apidocs/cts-query.html
  [JSON]: http://json.org
  [slides]: http://www.xmlprague.cz/2011/presentations/jason-hunter-mljson.pdf
