if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}

mljson.removeIndexes = function(info, callback) {
    var i = 0;
    var indexes = [];
    for(i = 0; i < info.indexes.fields.length; i += 1) {
        indexes.push({"type": "field", "name": info.indexes.fields[i].name});
    }
    for(i = 0; i < info.indexes.mappings.length; i += 1) {
        indexes.push({"type": "map", "name": info.indexes.mappings[i].name});
    }
    for(i = 0; i < info.indexes.ranges.length; i += 1) {
        indexes.push({"type": "range", "name": info.indexes.ranges[i].name});
    }
    
    var processingPosition = 0;

    var removeNextIndex = function() {
        removeIndex(processingPosition);
    };

    var removeIndex = function(pos) {
        var index = indexes[pos];
        if(index === undefined) {
            callback.call();
            return;
        }

        asyncTest("Remove the " + index.name + " index", function() {
            var url = "/data/manage/" + index.type + "/" + index.name;
            $.ajax({
                url: url,
                type: 'DELETE',
                success: function() {
                    processingPosition++;
                    removeNextIndex();
                },
                error: function(j, t, error) {
                    ok(false, "Could not delete index" + error);
                },
                complete: function() {
                    start();
                }
            });
        });
    }

    removeNextIndex();
};

$(document).ready(function() {
    module("Database setup");
    asyncTest("Database index setup", function() {
        $.ajax({
            url: '/data/info',
            success: function(data) {
                var info = JSON.parse(data);
                mljson.removeIndexes(info, function() {
                });
            },
            error: function() {
                ok(false, "Could not fetch server info");
            },
            complete: function() { start(); }
        });
    });
});
