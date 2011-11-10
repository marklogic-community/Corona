if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.fetchInfo = function(callback) {
    asyncTest("Fetching Corona state", function() {
        $.ajax({
            url: "/manage",
            success: function(data) {
                ok(true, "Fetched Corona state");
                callback.call(this, JSON.parse(data));
            },
            error: function(j, t, error) {
                ok(false, "Fetched Corona state");
                console.log("Could not fetch /manage: " + error);
            },
            complete: function() { start(); }
        });
    });
};
