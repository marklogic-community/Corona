if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.deleteEnvVar = function(name, callback) {
    asyncTest("Deleting var: " + name, function() {
        $.ajax({
            url: "/manage/env/" + name,
            type: 'DELETE',
            success: function() {
                ok(true, "Deleted var: " + name);
				$.ajax({
					url: "/manage/env",
					type: 'GET',
					success: function(data) {
						ok(true, "Get env");
                        equals(data[name], undefined, "Env var is gone: " + name);
						if(callback) {
							callback.call(this);
						}
					},
					error: function(j, t, error) {
						ok(false, "Get env");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Deleted var: " + name);
            }
        });
    });
};

corona.setInsertHook = function(name, callback) {
    asyncTest("Setting insert env to: " + name, function() {
        $.ajax({
            url: "/manage/env/insertTransformer",
            data: {value: name},
            type: 'POST',
            success: function() {
                ok(true, "Insert env set");
				$.ajax({
					url: "/manage/env",
					type: 'GET',
					success: function(data) {
						ok(true, "Get env");
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
						ok(false, "Get env");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Insert env set");
            }
        });
    });
};

corona.setFetchHook = function(name, callback) {
    asyncTest("Setting fetch env to: " + name, function() {
        $.ajax({
            url: "/manage/env/fetchTransformer",
            data: {value: name},
            type: 'POST',
            success: function() {
                ok(true, "Fetch env set");
				$.ajax({
					url: "/manage/env",
					type: 'GET',
					success: function(data) {
						ok(true, "Get env");
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
						ok(false, "Get env");
					},
                    complete: function() { start(); }
                });
            },
            error: function(j, t, error) {
                ok(false, "Fetch env set");
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
					corona.deleteEnvVar("insertTransformer", callback);
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
                            corona.deleteEnvVar("fetchTransformer", callback);
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
    module("Env Var Management");
	corona.testInsertHook(corona.testFetchHook);

});
