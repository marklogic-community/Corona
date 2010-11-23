xquery version "1.0-ml";

import module namespace json="http://marklogic.com/json" at "lib/json.xqy";

json:xmlToJson(root((/json/coordinates/coordinates)[1])/*)
