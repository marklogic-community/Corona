/*
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.search = {};

corona.search.fetch = function() {
    $.ajax("/manage", {
        success: function(data) {
            var addButton = $("<button style='float: right'>Add Constraint</button>");
            addButton.button().click(function() {
            });

            $("#jscontent").append(addButton);
            $("#jscontent").append($('<table id="search">'));
            var table = $("#search");
            table.append("<thead><tr><th>Name</th><th>Type</th><th>Summary</th><th>&nbsp</th></tr></thead>");
            var body = $("<tbody>");
            table.append(body);

            $.each(data.indexes.ranges, function(index, def) {
                var type = "key";
                if(def.attribute !== undefined) {
                    type = "attribute";
                }
                else if(def.element !== undefined) {
                    type = "element";
                }

                var summary = "";
                if(def.key !== undefined) {
                    summary = def.key + " (" + def.type + ")";
                }
                else if(def.attribute !== undefined) {
                    summary = def.element + "/@" + def.attribute + " (" + def.type + ")";
                }
                else if(def.element !== undefined) {
                    summary = def.element + " (" + def.type + ")";
                }

                body.append(corona.search.createRow("range", def.name, "Range (" + type + ")", summary));
            });

            $.each(data.indexes.bucketedRanges, function(index, def) {
                var type = "key";
                if(def.attribute !== undefined) {
                    type = "attribute";
                }
                else if(def.element !== undefined) {
                    type = "element";
                }

                var summary = "";
                if(def.key !== undefined) {
                    summary = def.key + " (" + def.type + ")";
                }
                else if(def.attribute !== undefined) {
                    summary = def.element + "/@" + def.attribute + " (" + def.type + ")";
                }
                else if(def.element !== undefined) {
                    summary = def.element + " (" + def.type + ")";
                }

                body.append(corona.search.createRow("bucketedRange", def.name, "Bucketed range (" + type + ")", summary));
            });

            $.each(data.indexes.places, function(index, def) {
                var numIncludes = 0;
                var numExcludes = 0;
                $.each(def.places, function(index, place) {
                    if(place.type = "include") {
                        numIncludes += 1;
                    }
                    else {
                        numExcludes += 1;
                    }
                });

                body.append(corona.search.createRow("place", def.name, "Place", numIncludes + " includes, " + numExcludes + " excludes"));
            });

            $.each(data.indexes.geo, function(index, def) {
                var summary = "";
                if(def.parentKey !== undefined) {
                    if(def.latKey !== undefined) {
                        summary = def.parentKey + "." + def.latKey + ", " + def.parentKey + "." + def.longKey;
                    }
                    else {
                        summary = def.parentKey + "." + def.key;
                    }
                }
                else if(def.parentElement !== undefined) {
                    if(def.latElement !== undefined) {
                        summary = def.parentElement + "/" + def.latElement + ", " + def.parentElement + "/" + def.longElement;
                    }
                    else if(def.element !== undefined) {
                        summary = def.parentElement + "/" + def.element;
                    }
                    else {
                        summary = def.parentElement + "/@" + def.latAttribute + ", " + def.parentElement + "/@" + def.longAttribute;
                    }
                }
                else if(def.key !== undefined) {
                    summary = def.key;
                }
                else if(def.element !== undefined) {
                    summary = def.element;
                }

                body.append(corona.search.createRow("geo", def.name, "Geospatial", summary));
            });

            var dataTable = table.dataTable({
                 "bDestroy": true,
                 "bJQueryUI": true,
                 "sPaginationType": "full_numbers",
                 "aoColumns": [ 
                    null,
                    null,
                    { "bSortable": false },
                    { "bSortable": false }
                ] 
            });
            corona.search.makeTableEditable(dataTable);
        },
        error: function(jqXHR, textStatus, error) {
            alert("Could not fetch search configuration: " + error);
        }
    });
};

corona.search.createRow = function(type, name, dataType, summary) {
    var tr = $('<tr id="search-' + name + '" class="searchtype-' + type + '">');
    tr.append("<td class='name'>" + name + "</td>");
    tr.append("<td class='type'>" + dataType + "</td>");
    tr.append("<td class='summary'>" + summary + "</td>");
    tr.append("<td class='delete'>Delete</td>");
    return tr;
};

corona.search.deleteRow = function() {
    var row = this.parentNode;
    corona.search.deleteByTableRow(row, function() {
        var dataTable = $("#search").dataTable();
        dataTable.fnDeleteRow(row);
        corona.search.makeTableEditable(dataTable);
    });
}

corona.search.deleteByTableRow = function(row, callback) {
    var name = row.id.replace(/^search-/, "");

    if(name !== "") {
        var url = "";

        if($(row).hasClass("searchtype-range")) {
            url = "/manage/range/" + name;
        }
        else if($(row).hasClass("searchtype-bucketedRange")) {
            url = "/manage/bucketedrange/" + name;
        }
        else if($(row).hasClass("searchtype-place")) {
            url = "/manage/place/" + name;
        }
        else if($(row).hasClass("searchtype-geo")) {
            url = "/manage/geospatial/" + name;
        }
        else if($(row).hasClass("searchtype-nqp")) {
            url = "/manage/namedqueryprefix/" + name;
        }

        $.ajax(url, {
            type: "DELETE",
            success: function() {
                callback.call();
            },
            error: function() {
                alert("Could not delete search configuration item");
            }
        });
    }
    else {
        if(callback !== undefined) {
            callback.call();
        }
    }
};

corona.search.makeTableEditable = function(table) {
    table.find("td.delete").click(corona.search.deleteRow);
};

$(document).ready(function() {
    corona.search.fetch();
});
