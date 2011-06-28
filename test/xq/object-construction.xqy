(:
Copyright 2011 MarkLogic Corporation

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

import module namespace json = "http://marklogic.com/json" at "/data/lib/json.xqy";


let $doc := json:document(
    json:object((
        "intvalue", 1,
        "floatvalue", 1.2,
        "boolvalue", true(),
        "nullvalue", json:null(),
        "arrayvalue", json:array((1, 2, 3)),
        "objectvalue", json:object(("foo", "bar")),
        "notrailingvalue"
    ))
)

return json:xmlToJSON($doc)
