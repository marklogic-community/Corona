#### The mljson project is a set of libraries and REST endpoints to enable the [MarkLogic] Server to become an advanced JSON store.
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
