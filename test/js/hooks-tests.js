if(typeof corona == "undefined" || !corona) {
    corona = {};
    corona.stash = {};
}

corona.setInsertHook = function(name, callback) {
    asyncTest("Setting insert hook to: " + name, function() {
        $.ajax({
            url: "/manage/hooks",
            data: {setInsertTransform: name},
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
					}
                });
            },
            error: function(j, t, error) {
                ok(false, "Insert hook set");
            },
			complete: function() { start(); }
        });
    });
};

corona.setFetchHook = function(name, callback) {
    asyncTest("Setting fetch hook to: " + name, function() {
        $.ajax({
            url: "/manage/hooks",
            data: {setFetchTransform: name},
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
					}
                });
            },
            error: function(j, t, error) {
                ok(false, "Fetch hook set");
            },
			complete: function() { start(); }
        });
    });
};

$(document).ready(function() {
    module("Hooks Management");
    corona.setInsertHook("adddate", function() {
		asyncTest("Inserting document", function() {
			$.ajax({
				url: "/store?uri=/auto-transform.xml&respondWithContent=true",
				data: "<foo/>",
				type: 'PUT',
				success: function(response) {
					ok(true, "Inserted document with auto-transform");
					equals(response.getElementsByTagName("wrapper").length, 1, "Transformer was applied to document");
					corona.setInsertHook("");
				},
				error: function(j, t, error) {
					ok(false, "Inserted document with auto-transform");
				},
				complete: function() { start(); }
			});
		});
    });

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
							corona.setFetchHook("");
						},
						error: function(j, t, error) {
							ok(false, "Fetching document with auto-transform");
						}
					});
				},
				error: function(j, t, error) {
					ok(false, "Inserted document");
				},
				complete: function() { start(); }
			});
		});
    });
});
