# Corona - A REST interface to MarkLogic

The Corona project is a set REST endpoints to enable usage of the [MarkLogic Server] without knowing XQuery.

## Installation

Installing Corona is fairly simple:

1. If you don't have a HTTP server configured in MarkLogic, create one
2. Set the URL rewriter for the HTTP server to: /data/lib/rewriter.xqy
3. Download the Corona source and unzip it underneath the document directory that you configured in the MarkLogic HTTP server

Feel free to remove the README file along with the test directory.
But keep the config and data directories structured as they are. You can
augment the functionality of Corona by writing your own XQuery and having it
live alongside the Corona files.

The URL rewritter is configured in the config/endpoints.xqy file. You can
change the URL structure or add in more rules if need be there.

## API Documentation
[Check the wiki for documentation on how to store, index and query the documents.](Corona/wiki)

  [MarkLogic Server]: http://developer.marklogic.com
  [CRUD]: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete
  [JSON]: http://json.org
