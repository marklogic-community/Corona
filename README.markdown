#### The MLJSON project is a set of libraries and REST endpoints to enable the [MarkLogic] Server to become an advanced JSON store.

The primary goal of the MLJSON project is to expose the tremendously powerful
document database and search engine features of [MarkLogic] to developers
without the need to learn XQuery.  Given that JSON is commonly used for 
serialization of objects and data along with the fact that most languages have
support for it makes it a very powerful format.  The JSON format combined with
the scalability of MarkLogic is extremely appealing.

Externally facing, MLJSON exposes REST endpoints that allow a developer to
easily store and retrieve JSON documents from the database ([CRUD]).  It also
exposes a very powerful query interface via specially constructed JSON objects.
This query interface allows the user to find documents via path expressions as
well as full text search expressions.  For those familiar with MarkLogic, it
exposes all of the functionality found in the [CTS search functions].

Internally, the library converts the JSON into XML that MarkLogic can
efficiently store and query.  While this format is intended to only be used
internally, there has been interest in exposing an API to XQuery developers
that would allow for the construction and modification of JSON documents stored
in the database.

___

## Files
 - lib/json.xqy - Has two public functions:
   - jsonToXML - parses a JSON string into XML that can be stored in MarkLogic
   - xmlToJSON - parses the generated XML into a JSON string
 - lib/json-path.xqy - Tinkering with ways to query the stored JSON
 - jsonquery.xqy - A REST endpoint for querying JSON documents
 - jsonstore.xqy - A REST endpoint for storing, managing and retrieving JSON documents

## Capabilities of jsonstore.xqy
#### Insert a JSON document
 - Request type: PUT
 - Request body should be the JSON document
 - Example: jsonstore.xqy?uri=/foo/bar.json
 - Optional: When inserting a document you can set permissions, collections and a document quality.
   - jsonstore.xqy?uri=/foo/bar.json&permission=public:read&permission=admin:write
   - jsonstore.xqy?uri=/foo/bar.json&collection=public&collection=published
   - jsonstore.xqy?uri=/foo/bar.json&quality=10
   - jsonstore.xqy?uri=/foo/bar.json&permission=public:read&collection=public&quality=10

#### Get a JSON document
 - Request type: GET
 - Example: jsonstore.xqy?uri=/foo/bar.json

#### Delete a JSON document
 - Request type: DELETE
 - Example: jsonstore.xqy?uri=/foo/bar.json

#### Set a property on a document
 - Request type: POST
 - Properties are **not** held inside the JSON document, properties are stored outside of the document and don't effect the stored document at all.  They are best thought of as metadata about the document but should be avoided if possible due to storage overhead.
 - Example: jsonstore.xqy?uri=/foo/bar.json&property=publishState:final&property=needsEditorial:false

#### Get a property of a document
 - Request type: GET
 - Returns the value of a property that has been set on a document.
 - Example: jsonstore.xqy?uri=/foo/bar.json&property=publishState

#### Set permissions on a document
 - Request type: POST
 - When setting permissions on a document, all of the existing permissions are overwritten.
 - Example: jsonstore.xqy?uri=/foo/bar.json&permission=public:read&permission=admin:write

#### Set collections on a document
 - Request type: POST
 - When setting collections on a document, all of the existing collections are overwritten.
 - Example: jsonstore.xqy?uri=/foo/bar.json&collection=public&collection=published

#### Set the quality of a document
 - Request type: POST
 - Example: jsonstore.xqy?uri=/foo/bar.json&quality=10

## TODO
 - lib/json.xqy:
   - Convert \n to newlines
   - Convert wide encoded unicode chars: \uFFFF\uFFFF
   - Sanitize element names
 - lib/json-path.xqy:
   - Almost everything
 - jsonstore.xqy:
   - Move a document
   - Copy a document
   - Get the document permissions
   - Get the document collections
   - Get the document quality
 - Some real tests

  [MarkLogic]: http://marklogic.com
  [CRUD]: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete
  [CTS search functions]: http://developer.marklogic.com/pubs/4.2/apidocs/cts-query.html
