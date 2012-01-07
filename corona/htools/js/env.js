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

corona.envvars = {};

corona.envvars.fetch = function() {
    $.ajax("/manage/env", {
        success: function(data) {
            var addButton = $("<button style='float: right'>Add Variable</button>");
            addButton.button().click(function() {
                dataTable.fnAddTr(corona.envvars.createRow("", "").get(0));
                corona.envvars.makeTableEditable(dataTable);
            });

            $("#jscontent").append(addButton);
            $("#jscontent").append($('<table id="envvars">'));
            var table = $("#envvars");
            table.append("<thead><tr><th>Variable</th><th>Value</th><th>&nbsp;</th></tr></thead>");
            var body = $("<tbody>");
            table.append(body);

            $.each(data, function(key, value) {
                body.append(corona.envvars.createRow(key, value));
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
            corona.envvars.makeTableEditable(dataTable);
        },
        error: function(jqXHR, textStatus, error) {
            alert("Could not fetch environment variables: " + error);
        }
    });
};

corona.envvars.createRow = function(name, value) {
    var tr = $('<tr id="envvar-' + name + '">');
    tr.append("<td class='name'>" + name + "</td>");
    tr.append("<td class='value'>" + value + "</td>");
    tr.append("<td class='delete'>Delete</td>");
    return tr;
};

corona.envvars.deleteRow = function() {
    var row = this.parentNode;
    var name = row.id.replace(/^envvar-/, "");

    if(name !== "") {
        $.ajax("/manage/env/" + name, {
            type: "DELETE",
            success: function() {
                var dataTable = $("#envvars").dataTable();
                dataTable.fnDeleteRow(row);
            },
            error: function() {
                alert("Could not delete environment variable");
            }
        });
    }
    else {
        var dataTable = $("#envvars").dataTable();
        dataTable.fnDeleteRow(row);
    }
}

corona.envvars.makeTableEditable = function(table) {
    table.makeEditable({
        sUpdateURL: function(newValue, settings) {
            var row = this.parentNode;
            var currentName = row.id.replace(/^envvar-/, "");
            var nameCell = $(row).find("td.name");
            var valueCell = $(row).find("td.value");
            var name = undefined;
            var value = undefined;

            if(nameCell.get(0) === this) {
                name = newValue;
            }
            else {
                name = nameCell.text();
            }
            if(valueCell.get(0) === this) {
                value = newValue;
            }
            else {
                value = valueCell.text();
            }

            if(currentName !== "" && currentName !== name && row.id !== "envvar-") {
                $.ajax("/manage/env/" + currentName, {
                    type: "DELETE",
                    success: function() {
                        corona.envvars.setVariable(row, name, value);
                    },
                    error: function() {
                        alert("Could not update the variable name");
                    }
                });
            }
            else {
                corona.envvars.setVariable(row, name, value);
            }

            return newValue;
        },
        sDeleteURL: function() { return true; },
        aoColumns: [{}, {}, null]
    });

    table.find("td.delete").click(corona.envvars.deleteRow);
};

corona.envvars.setVariable = function(row, name, value) {
    $.ajax("/manage/env/" + name, {
        type: "POST",
        data: {"value": value},
        success: function() {
            row.id = "envvar-" + name;
        },
        error: function() {
            alert("Could not update environment variable");
        }
    });
};

$(document).ready(function() {
    corona.envvars.fetch();
});

