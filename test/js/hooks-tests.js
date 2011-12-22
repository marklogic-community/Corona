if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.deleteHook = function(hook, callback) {
    asyncTest("Deleting hook: " + hook, function() {
        $.ajax({
            url: "/manage/hooks?hook=" + hook,
            type: 'DELETE',
            success: function() {
                ok(true, "Deleted hook: " + hook);
				$.ajax({
					url: "/manage/hooks",
					type: 'GET',
					success: function(data) {
						ok(true, "Get hooks");
                        equals(data.insertTransformer, undefined, "Hook is gone: " + hook);
						if(callback) {
							callback.call(this);
						}
					},
					error: function(j, t, error) {
						ok(false, "Get hooks");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Deleted hook: " + hook);
            }
        });
    });
};

corona.setInsertHook = function(name, callback) {
    asyncTest("Setting insert hook to: " + name, function() {
        $.ajax({
            url: "/manage/hooks",
            data: {insertTransformer: name},
            type: 'POST',
            success: function() {
                ok(true, "Insert hook set");
				$.ajax({
					url: "/manage/hooks",
					type: 'GET',
					success: function(data) {
						ok(true, "Get hooks");
						if(name !== "") {
							equals(data.insertTransformer, name, "Insert transformer set to: " + name);
						}
						else {
							equals(data.insertTransformer, undefined, "Insert transformer removed");
						}
						if(callback) {
							callback.call(this);
						}
					},
					error: function(j, t, error) {
						ok(false, "Get hooks");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Insert hook set");
            }
        });
    });
};

corona.setFetchHook = function(name, callback) {
    asyncTest("Setting fetch hook to: " + name, function() {
        $.ajax({
            url: "/manage/hooks",
            data: {fetchTransformer: name},
            type: 'POST',
            success: function() {
                ok(true, "Fetch hook set");
				$.ajax({
					url: "/manage/hooks",
					type: 'GET',
					success: function(data) {
						ok(true, "Get hooks");
						if(name !== "") {
							equals(data.fetchTransformer, name, "Fetch transformer set to: " + name);
						}
						else {
							equals(data.fetchTransformer, undefined, "Fetch transformer removed");
						}
						if(callback) {
							callback.call(this);
						}
					},
					error: function(j, t, error) {
						ok(false, "Get hooks");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Fetch hook set");
            }
        });
    });
};

corona.testInsertHook = function(callback) {
    corona.setInsertHook("adddate", function() {
		asyncTest("Inserting document", function() {
			$.ajax({
				url: "/store?uri=/auto-transform.xml&respondWithContent=true",
				data: "<foo/>",
				type: 'PUT',
				success: function(response) {
					ok(true, "Inserted document with auto-transform");
					equals(response.getElementsByTagName("wrapper").length, 1, "Transformer was applied to document");
					corona.deleteHook("insertTransformer", callback);
				},
				error: function(j, t, error) {
					ok(false, "Inserted document with auto-transform");
				},
				complete: function() { start(); }
			});
		});
    });
};

corona.testFetchHook = function(callback) {
    corona.setFetchHook("adddate", function() {
		asyncTest("Inserting document", function() {
			$.ajax({
				url: "/store?uri=/auto-transform-on-fetch.xml",
				data: "<foo/>",
				type: 'PUT',
				success: function(response) {
					$.ajax({
						url: "/store?uri=/auto-transform-on-fetch.xml",
						type: 'GET',
						success: function(response) {
							ok(true, "Fetching document with auto-transform");
							equals(response.getElementsByTagName("wrapper").length, 1, "Transformer was applied to document");
                            corona.deleteHook("fetchTransformer", callback);
						},
						error: function(j, t, error) {
							ok(false, "Fetching document with auto-transform");
						},
                        complete: function() { start(); }
					});
				},
				error: function(j, t, error) {
					ok(false, "Inserted document");
				}
			});
		});
    });
};


$(document).ready(function() {
    module("Hooks Management");
	corona.testInsertHook(corona.testFetchHook);

});
