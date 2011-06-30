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

## REST Capabilities
### Document management
#### Insert a JSON document
 - Request type: PUT or POST
 - Request body should be the JSON document
 - Example: /data/store/foo/bar.json - Will insert the document in the database with a uri of "/foo/bar.json"
 - Optional: When inserting a document you can set permissions, properties, collections and a document quality.
   - /data/store/foo/bar.json?permission=public:read&permission=admin:write
   - /data/store/foo/bar.json?property=key:value&property=published:false
   - /data/store/foo/bar.json?collection=public&collection=published
   - /data/store/foo/bar.json?quality=10
   - /data/store/foo/bar.json?permission=public:read&collection=public&quality=10

 - Notes:
   - You can set multiple permissions, properties and collections by including multiple definitions in your request, as shown above
   - Permissions must follow a <role>:<capability> pattern where capability is one of read, update or execute
   - Properties must follow a <key>:<value> pattern where the key is alphanumeric and starts with a letter

#### Get a JSON document
 - Request type: GET
 - Example: /data/store/foo/bar.json - Get the document with a uri of "/foo/bar.json"
 - Optional: To fetch metadata associated about the document, specify what you'd like to include in the response.
   - /data/store/foo/bar.json?include=content - Simply returns the document as supplied via the PUT (default)
   - /data/store/foo/bar.json?include=permissions - Returns the permissions on the document
   - /data/store/foo/bar.json?include=collections - Returns the collections on the document
   - /data/store/foo/bar.json?include=properties - Returns the properties on the document
   - /data/store/foo/bar.json?include=quality - Returns the quality of the document
   - /data/store/foo/bar.json?include=content&include=permissions&include=quality - Returns the content, permissions and quality of the document
   - /data/store/foo/bar.json?include=all - Returns the content along with all of its metadata

#### Delete a JSON document
 - Request type: DELETE
 - Example: /data/store/foo/bar.json - Delete the document with a uri of "/foo/bar.json"

#### Set a property on a document
 - Request type: POST
 - Properties are **not** held inside the JSON document, properties are stored outside of the document and don't effect the stored document at all.  They are best thought of as metadata about the document but should be avoided if possible due to storage overhead.
 - Example: /data/store/foo/bar.json?property=publishState:final&property=needsEditorial:false

#### Set permissions on a document
 - Request type: POST
 - When setting permissions on a document, all of the existing permissions are overwritten.
 - Example: /data/store/foo/bar.json?permission=public:read&permission=admin:write

#### Set collections on a document
 - Request type: POST
 - When setting collections on a document, all of the existing collections are overwritten.
 - Example: /data/store/foo/bar.json?collection=public&collection=published

#### Set the quality of a document
 - Request type: POST
 - Example: /data/store/foo/bar.json?quality=10

### Key/Value queries
The key/value query endpoint allows you to easily grab the first document that
contains the key/value combination. Multple keys are and'd together and
multiple values for the same key are or'd together.

 - Request type: GET
 - Examples:
   - /data/kvquery?foo=bar - Document that has a 'foo' key with a value of 'bar'
   - /data/kvquery?foo=bar&baz=yaz - Document that has a 'foo' key with a value of 'bar' and a 'baz' key with a value of 'yaz'
   - /data/kvquery?foo=bar&foo=bar - Document that has a 'foo' key with a value of 'bar' or 'baz'

## Index management
### Fields
A field groups together a number of keys so their values are treated as one
block of text.  Lets say you have two keys, "first_name" and "last_name" that
you'd like to query as though they were one key "name".  Creating a field
called "name" that includes both "first_name" and "last_name" is an easy way to
accomplish this.

#### Get info about a field
Returns what keys are included and excluded in a field.

 - Request type: GET
 - Example:
    - /data/manage/field/my_field_name

#### Create a field
Creates a field in the database. Fields can not share the same name as range
indexes or aliases, they must be unique. If the value of the incluced key is an
object, you can exclude child keys in that object by adding an exclude
parameter in the request.

 - Request type: PUT|POST
 - Examples:
   - /data/manage/field/my_field_name?include=first_name&include=last_name
   - /data/manage/field/my_field_name?include=first_name&include=last_name&exclude=middle_name

#### Delete a field
Deletes the field.

 - Request type: PUT|POST
 - Example:
   - /data/manage/field/my_field_name

### Range indexes
A range index allows you to perform queries over a range of values.  For
example, if you want to fetch all documents where the "pub_date" is after
2011-01-01, you would add a range index on the "pub_date" key.

#### Get info about a range index
Returns information about how a range index is configured.

 - Request type: GET
 - Example:
   - /data/manage/range/publication-date

#### Create a range index
Creates a range index in the database. Range indexes can not share the same name as fields
or aliases, they must be unique. You must specify the key to create the range
index on, the datatype (number, string or date) and the operator (eq, ne, lt,
le, gt or ge).

 - Request type: PUT|POST
 - Examples:
   - /data/manage/range/date?key=pub_date&datatype=date&operator=eq
   - /data/manage/range/date-before?key=pub_date&datatype=date&operator=lt
   - /data/manage/range/date-after?key=pub_date&datatype=date&operator=gt

#### Delete a range index
Deletes the range index.

 - Request type: DELETE
 - Example:
    - /data/manage/range/date-before

## Server information
Information about the MarkLogic server version, hardware and index settings can be obtained with an info request.

 - Request type: GET
 - Example: /data/info

## TODO
 - Move a document
 - Copy a document

  [MarkLogic]: http://developer.marklogic.com
  [MarkLogic Server]: http://developer.marklogic.com
  [CRUD]: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete
  [CTS search functions]: http://developer.marklogic.com/pubs/4.2/apidocs/cts-query.html
  [JSON]: http://json.org
  [slides]: http://www.xmlprague.cz/2011/presentations/jason-hunter-mljson.pdf
