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

corona.transformers = {};

corona.transformers.fetch = function() {
    $.ajax("/manage/transformers", {
        success: function(data) {
            var addButton = $("<button style='float: right'>Add Transformer</button>");
            addButton.button().click(function() {
                $("#newTransfomerDialog").dialog("open");
            });

            $("#jscontent").append(addButton);
            $("#jscontent").append($('<table id="transformers">'));
            var table = $("#transformers");
            table.append("<thead><tr><th>Name</th><th>Type</th><th>&nbsp;</th><th>&nbsp</th></tr></thead>");
            var body = $("<tbody>");
            table.append(body);

            $.each(data, function(index, def) {
                body.append(corona.transformers.createRow(def.name, def.type));
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
            corona.transformers.makeTableEditable(dataTable);
        },
        error: function(jqXHR, textStatus, error) {
            alert("Could not fetch list of transformers: " + error);
        }
    });
};

corona.transformers.reload = function(callback) {
    $.ajax("/manage/transformers", {
        success: function(data) {
            var dataTable = $("#transformers").dataTable();

            $("#transformers tbody tr").each(function(index, row) {
                dataTable.fnDeleteRow(row);
            });

            $.each(data, function(index, def) {
                dataTable.fnAddTr(corona.transformers.createRow(def.name, def.type).get(0));
            });

            corona.transformers.makeTableEditable(dataTable);
            if(callback !== undefined) {
                callback.call();
            }
        },
        error: function(jqXHR, textStatus, error) {
            alert("Could not fetch list of transformers: " + error);
        }
    });
};

corona.transformers.createRow = function(name, type) {
    var tr = $('<tr id="transformer-' + name + '">');
    tr.append("<td class='name'>" + name + "</td>");
    tr.append("<td class='type'>" + type + "</td>");
    tr.append("<td class='edit'>Edit</td>");
    tr.append("<td class='delete'>Delete</td>");
    return tr;
};

corona.transformers.deleteRow = function() {
    var row = this.parentNode;
    var name = row.id.replace(/^transformer-/, "");

    if(name !== "") {
        $.ajax("/manage/transformer/" + name, {
            type: "DELETE",
            success: function() {
                var dataTable = $("#transformers").dataTable();
                dataTable.fnDeleteRow(row);
            },
            error: function() {
                alert("Could not delete transformer");
            }
        });
    }
    else {
        var dataTable = $("#transformers").dataTable();
        dataTable.fnDeleteRow(row);
    }
}

corona.transformers.makeTableEditable = function(table) {
    table.makeEditable({
        sUpdateURL: function(newValue, settings) {
            var row = this.parentNode;
            var currentName = row.id.replace(/^transformer-/, "");
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

            if(currentName !== "" && currentName !== name && row.id !== "transformer-") {
                $.ajax("/manage/transformer/" + currentName, {
                    type: "DELETE",
                    success: function() {
                        corona.transformers.createTransformer(row, name, value);
                    },
                    error: function() {
                        alert("Could not update the transformer name");
                    }
                });
            }
            else {
                corona.transformers.createTransformer(row, name, value);
            }

            return newValue;
        },
        sDeleteURL: function() { return true; },
        aoColumns: [{}, null, null, null]
    });

    table.find("td.edit").click(corona.transformers.editTransformer);
    table.find("td.delete").click(corona.transformers.deleteRow);
};

corona.transformers.editTransformer = function() {
    var row = this.parentNode;
    var name = row.id.replace(/^transformer-/, "");

    if(name !== "") {
        $("#editTransformerName").val(name);

        $.ajax("/manage/transformer/" + name, {
            success: function(data, textStatus, jqXHR) {
                $("#editTransformerContent").val(jqXHR.responseText);
                $("#editTransfomerDialog").dialog("open");
            },
            error: function() {
                alert("Could not update the transformer name");
            }
        });
    }
};

corona.transformers.createTransformer = function(row, name, value) {
    $.ajax("/manage/transformer/" + name, {
        type: "PUT",
        data: value,
        success: function() {
            row.id = "transformer-" + name;
        },
        error: function() {
            alert("Could not update transformer");
        }
    });
};

$(document).ready(function() {

    var checkNotEmpty = function(o, n) {
        if(o.val().length === 0) {
            o.addClass("ui-state-error");
            updateTips("The " + n + " can not be empty")
            return false;
        }
        else {
            return true;
        }
    };

    var newTransformerName = $("#newTransformerName");
    var newTransformerContent = $("#newTransformerContent");
    allFields = $([]).add(newTransformerName).add(newTransformerContent);

    $("#newTransfomerDialog").dialog({
        autoOpen: false,
        height: 600,
        width: 750,
        modal: true,
        buttons: {
            "Create transformer": function() {
                var isValid = true;
                allFields.removeClass("ui-state-error");
                isValid = isValid && checkNotEmpty(newTransformerName, "transformer name");
                isValid = isValid && checkNotEmpty(newTransformerContent, "transformer content");

                if(isValid) {
                    $.ajax("/manage/transformer/" + newTransformerName.val(), {
                        type: "PUT",
                        data: newTransformerContent.val(),
                        success: function() {
                            corona.transformers.reload(function() {
                                $("#newTransfomerDialog").dialog("close");
                            });
                        },
                        error: function() {
                            alert("Could not create transformer");
                        }
                    });
                }

            },
            Cancel: function() {
                $(this).dialog("close");
            }
        },
        close: function() {
            allFields.val("").removeClass("ui-state-error");
        }
    });

    var editTransformerName = $("#editTransformerName");
    var editTransformerContent = $("#editTransformerContent");
    allFields = $([]).add(editTransformerName).add(editTransformerContent);

    $("#editTransfomerDialog").dialog({
        autoOpen: false,
        height: 600,
        width: 750,
        modal: true,
        buttons: {
            "Save transformer": function() {
                var isValid = true;
                allFields.removeClass("ui-state-error");
                isValid = isValid && checkNotEmpty(editTransformerContent, "transformer content");

                if(isValid) {
                    $.ajax("/manage/transformer/" + editTransformerName.val(), {
                        type: "PUT",
                        data: editTransformerContent.val(),
                        success: function() {
                            corona.transformers.reload(function() {
                                $("#editTransfomerDialog").dialog("close");
                            });
                        },
                        error: function() {
                            alert("Could not save transformer");
                        }
                    });
                }

            },
            Cancel: function() {
                $(this).dialog("close");
            }
        },
        close: function() {
            allFields.val("").removeClass("ui-state-error");
        }
    });


    corona.transformers.fetch();
});
