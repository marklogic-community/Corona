if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.getState = function(startTests, callback) {
    $.ajax({
        url: '/manage',
        type: 'GET',
        success: function(data) {
            callback.call(this, JSON.parse(data));
        },
        complete: function() { if(startTests) { start(); } }
    });
};

corona.setManaged = function(isManaged, callback) {
    asyncTest("Setting managed to: " + isManaged, function() {
        $.ajax({
            url: "/manage",
            data: {isManaged: isManaged},
            type: 'POST',
            success: function() {
                ok(true, "State set");
                corona.getState(true, function(state) {
                    ok(state.isManaged === isManaged, "State set to: " + isManaged);
                    if(callback) {
                        callback.call(this);
                    }
                });
            },
            error: function(j, t, error) {
                ok(false, "State set");
            }
        });
    });
};

$(document).ready(function() {
    module("State Management");
    corona.setManaged(false, function() {
        corona.setManaged(true);
    });
});
