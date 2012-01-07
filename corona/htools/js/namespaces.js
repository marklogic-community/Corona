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

corona.namespaces = {};

corona.namespaces.fetch = function() {
    $.ajax("/manage/namespaces", {
        success: function(data) {
            var addButton = $("<button style='float: right'>Add Namespace</button>");
            addButton.button().click(function() {
                dataTable.fnAddTr(corona.namespaces.createRow("", "").get(0));
                corona.namespaces.makeTableEditable(dataTable);
            });

            $("#jscontent").append(addButton);
            $("#jscontent").append($('<table id="namespaces">'));
            var table = $("#namespaces");
            table.append("<thead><tr><th>Prefix</th><th>URI</th><th>&nbsp;</th></tr></thead>");
            var body = $("<tbody>");
            table.append(body);

            $(data).each(function(index, def) {
                body.append(corona.namespaces.createRow(def.prefix, def.uri));
            });

            var dataTable = table.dataTable({
                 "bJQueryUI": true,
                 "sPaginationType": "full_numbers",
                 "aoColumns": [ 
                    null,
                    null,
                    { "bSortable": false }
                ] 
            });
            corona.namespaces.makeTableEditable(dataTable);
        },
        error: function(jqXHR, textStatus, error) {
            alert("Could not fetch namespaces: " + error);
        }
    });
};

corona.namespaces.createRow = function(prefix, uri) {
    var tr = $('<tr id="namespace-' + prefix + '">');
    tr.append("<td class='prefix'>" + prefix + "</td>");
    tr.append("<td class='uri'>" + uri + "</td>");
    tr.append("<td class='delete'>Delete</td>");
    return tr;
};

corona.namespaces.deleteRow = function() {
    var row = this.parentNode;
    var prefix = row.id.replace(/^namespace-/, "");

    if(prefix !== "") {
        $.ajax("/manage/namespace/" + prefix, {
            type: "DELETE",
            success: function() {
                var dataTable = $("#namespaces").dataTable();
                dataTable.fnDeleteRow(row);
            },
            error: function() {
                alert("Could not delete namespace");
            }
        });
    }
    else {
        var dataTable = $("#namespaces").dataTable();
        dataTable.fnDeleteRow(row);
    }
}

corona.namespaces.makeTableEditable = function(table) {
    table.makeEditable({
        sUpdateURL: function(value, settings) {
            var row = this.parentNode;
            var currentPrefix = row.id.replace(/^namespace-/, "");
            var prefixCell = $(row).find("td.prefix");
            var uriCell = $(row).find("td.uri");
            var prefix = undefined;
            var uri = undefined;

            if(prefixCell.get(0) === this) {
                prefix = value;
            }
            else {
                prefix = prefixCell.text();
            }
            if(uriCell.get(0) === this) {
                uri = value;
            }
            else {
                uri = uriCell.text();
            }

            if(currentPrefix !== "") {
                $.ajax("/manage/namespace/" + currentPrefix, {
                    type: "DELETE",
                    success: function() {
                        corona.namespaces.createNamespace(row, prefix, uri);
                    },
                    error: function() {
                        corona.namespaces.createNamespace(row, prefix, uri);
                    }
                });
            }
            else {
                corona.namespaces.createNamespace(row, prefix, uri);
            }

            return value;
        },
        sDeleteURL: function() { return true; },
        aoColumns: [{}, {}, null]
    });

    table.find("td.delete").click(corona.namespaces.deleteRow);
};

corona.namespaces.createNamespace = function(row, prefix, uri) {
    $.ajax("/manage/namespace/" + prefix, {
        type: "POST",
        data: {"uri": uri},
        success: function() {
            row.id = "namespace-" + prefix;
        },
        error: function() {
            alert("Could not update namespace");
        }
    });
};

$(document).ready(function() {
    corona.namespaces.fetch();
});
