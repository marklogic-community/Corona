if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.startTransaction = function(supportsTransactions, callback) {
    asyncTest("Starting transaction", function() {
        $.ajax({
            url: "/transaction/create",
            type: 'POST',
            data: {outputFormat: "json"},
            success: function(data) {
                ok(supportsTransactions === true, "Created transaction");
                callback.call(this, JSON.parse(data).txid);
            },
            error: function(j, t, error) {
                ok(supportsTransactions === false, "Could not create transaction");
            },
            complete: function() { start(); }
        });
    });
};

corona.rollbackTransaction = function(txid, callback) {
    asyncTest("Rolling back transaction", function() {
        $.ajax({
            url: "/transaction/rollback",
            type: 'POST',
            data: {outputFormat: "json", txid: txid},
            success: function(data) {
                ok(true, "Rolled back transaction");
                callback.call(this);
            },
            error: function(j, t, error) {
                ok(false, "Could not roll back transaction");
            },
            complete: function() { start(); }
        });
    });
};

corona.commitTransaction = function(txid, callback) {
    asyncTest("Commit transaction", function() {
        $.ajax({
            url: "/transaction/commit",
            type: 'POST',
            data: {outputFormat: "json", txid: txid},
            success: function(data) {
                ok(true, "Committed transaction");
                callback.call(this);
            },
            error: function(j, t, error) {
                ok(false, "Could not commit transaction");
            },
            complete: function() { start(); }
        });
    });
};

corona.loadDocument = function(doc, uri, txid, callback) {
    asyncTest("Loading document", function() {
        var url = "/store" + uri;
        if(txid) {
            url += "?txid=" + txid;
        }
        $.ajax({
            url: url,
            type: 'PUT',
            data: JSON.stringify(doc),
            success: function(data) {
                ok(true, "Loaded document in transaction");
                callback.call(this);
            },
            error: function(j, t, error) {
                ok(false, "Loaded document in transaction");
            },
            complete: function() { start(); }
        });
    });
};

corona.docExists = function(uri, txid, shouldExist, callback) {
    var desc;
    if(txid) {
        if(shouldExist) {
            desc = "Testing for existance in transaction";
        }
        else {
            desc = "Testing for non-existance in transaction";
        }
    }
    else {
        if(shouldExist) {
            desc = "Testing for existance outside of transaction";
        }
        else {
            desc = "Testing for non-existance outside of transaction";
        }
    }
    asyncTest(desc, function() {
        var url = "/store" + uri;
        if(txid) {
            url += "?txid=" + txid;
        }
        $.ajax({
            url: url,
            type: 'GET',
            success: function(data) {
                ok(shouldExist === true, "Document exists");
                callback.call(this);
            },
            error: function(j, t, error) {
                ok(shouldExist === false, "Document exists");
                callback.call(this);
            },
            complete: function() { start(); }
        });
    });
};

corona.supportsTransactions = function(callback) {
    $.ajax({
        url: "/manage",
        type: 'GET',
        success: function(data) {
            var serverVersion = JSON.parse(data).serverVersion;
            callback.call(this, serverVersion.substring(0, 1) === "5");
        }
    });
};

$(document).ready(function() {
    corona.supportsTransactions(function(supportsTransactions) {
    module("Transaction Management");
// Start a new transaction
    corona.startTransaction(supportsTransactions, function(transactionID) {
// Load a document in that transaction and see if it's visible inside the transaction
        var uri = "/transactions/" + transactionID + ".json";
        corona.loadDocument({"transactionDoc": "txtest"}, uri, transactionID, function() {
            corona.docExists(uri, transactionID, true, function() {
// Rollback the transaction and make sure the doc doesn't exist
                corona.rollbackTransaction(transactionID, function() {
                    corona.docExists(uri, undefined, false, function() {});

// Start another new transaction
                    corona.startTransaction(supportsTransactions, function(transactionID) {
                        var uri = "/transactions/" + transactionID + ".json";
// Load a document under that transaction and make sure it isn't visible outside of the transaction
                        corona.loadDocument({"transactionDoc": "txtest"}, uri, transactionID, function() {
                            corona.docExists(uri, undefined, false, function() {
// Commit the transaction and make sure the doc is visible
                                corona.commitTransaction(transactionID, function() {
                                    window.setTimeout(function() {
                                        corona.docExists(uri, undefined, true, function() {});
                                    }, 1000);
                                });
                            });
                        });
                    });
                });
            });
        });
    });
    });
});
