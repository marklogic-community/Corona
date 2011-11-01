if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.startTransaction = function(callback) {
    asyncTest("Starting transaction", function() {
        $.ajax({
            url: "/transaction/create",
            type: 'POST',
            data: {outputFormat: "json"},
            success: function(data) {
                $.cookie("SessionID", null);
                ok(true, "Created transaction");
                callback.call(this, JSON.parse(data).txid);
            },
            error: function(j, t, error) {
                ok(false, "Could not create transaction");
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

$(document).ready(function() {
    module("Transaction Management");
    corona.startTransaction(function(transactionID) {
        corona.rollbackTransaction(transactionID, function() {
            corona.startTransaction(function(transactionID) {
                corona.commitTransaction(transactionID, function() {
                });
            });
        });
    });
});
