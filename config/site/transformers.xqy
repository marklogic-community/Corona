(:
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
:)

xquery version "1.0-ml";

import module namespace template="http://marklogic.com/corona/template" at "/corona/htools/template.xqy";

template:apply(
    <div>
        <h2>Transformers</h2>
        <div id="jscontent"><!-- --></div>
        <div id="newTransfomerDialog" title="Create new transformer">
            <form>
                <label for="name">Name</label><br/>
                <input type="text" name="name" id="newTransformerName" class="text ui-widget-content ui-corner-all" /><br/>
                <textarea id="newTransformerContent" style="width: 100%; height: 380px;" class="transformer">&nbsp;</textarea>
            </form>
        </div>
        <div id="editTransfomerDialog" title="Edit transformer">
            <form>
                <label for="name">Name</label><br/>
                <input type="text" name="name" id="editTransformerName" disabled="true" class="text ui-widget-content ui-corner-all" /><br/>
                <textarea id="editTransformerContent" style="width: 100%; height: 380px;" class="transformer">&nbsp;</textarea>
            </form>
        </div>
    </div>,
    "Transformers - Corona",
    (
        <li><h4><a href="/config/search">Search</a></h4></li>,
        <li><h4><a href="/config/namespaces">XML Namespaces</a></h4></li>,
        <li><h4><a href="/config/transformers">Transformers</a></h4></li>,
        <li><h4><a href="/config/env">Environment Vars</a></h4></li>
    ),
    3,
    (
        <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.7/jquery-ui.min.js"><!-- --></script>,
        <script src="/corona/htools/js/DataTables-1.8.2/js/jquery.dataTables.min.js"><!-- --></script>,
        <script src="/corona/htools/js/DataTables-1.8.2/js/jquery.jeditable.js"><!-- --></script>,
        <script src="/corona/htools/js/DataTables-1.8.2/js/jquery.dataTables.editable.js"><!-- --></script>,
        <script src="/corona/htools/js/transformers.js"><!-- --></script>
    ),
    (
        <link rel="stylesheet" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.7/themes/smoothness/jquery-ui.css" type="text/css" />,
        <link rel="stylesheet" href="/corona/htools/js/DataTables-1.8.2/css/demo_table_jui.css" type="text/css" media="screen, projection" />
    )
)
