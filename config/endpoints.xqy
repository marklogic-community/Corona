xquery version "1.0-ml";

module namespace endpoints="http://marklogic.com/corona/endpoints";

import module namespace rest="http://marklogic.com/appservices/rest" at "/corona/lib/rest/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $endpoints:ENDPOINTS as element(rest:options) :=
<options xmlns="http://marklogic.com/appservices/rest">
    <!-- Manage documents in the database -->
    <request uri="^/store/?$" endpoint="/corona/store-get.xqy" user-params="allow">
        <param name="uri" required="false"/>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="outputFormat" required="false" values="json|xml"/>
    </request>

    <request uri="^/store/?$" endpoint="/corona/store.xqy" user-params="allow">
        <param name="uri" required="false"/>
        <param name="txid" required="false"/>

        <http method="GET">
            <param name="stringQuery" required="false"/>
            <param name="structuredQuery" required="false"/>
            <param name="extractPath" required="false"/>
            <param name="applyTransform" required="false"/>
            <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
            <param name="outputFormat" required="false" values="json|xml"/>
        </http>
        <http method="POST">
            <param name="contentType" required="false" values="json|xml|text|binary"/>
            <param name="collection" alias="collection[]" repeatable="true" required="false"/>
            <param name="addCollection" alias="addCollection[]" repeatable="true" required="false"/>
            <param name="removeCollection" alias="removeCollection[]" repeatable="true" required="false"/>
            <param name="property" alias="property[]" repeatable="true" required="false"/>
            <param name="addProperty" alias="addProperty[]" repeatable="true" required="false"/>
            <param name="removeProperty" alias="removeProperty[]" repeatable="true" required="false"/>
            <param name="permission" alias="permission[]" repeatable="true" required="false"/>
            <param name="addPermission" alias="addPermission[]" repeatable="true" required="false"/>
            <param name="removePermission" alias="removePermission[]" repeatable="true" required="false"/>
            <param name="quality" required="false"/>
			<param name="language" required="false" />
            <param name="contentForBinary" required="false"/>
            <param name="moveTo" required="false"/>
            <param name="extractMetadata" required="false" as="boolean" default="true"/>
            <param name="extractContent" required="false" as="boolean" default="true"/>
            <param name="applyTransform" required="false"/>
            <param name="respondWithContent" required="false" as="boolean" default="false"/>
            <param name="repair" required="false" as="boolean" default="false"/>
        </http>
        <http method="PUT">
            <param name="contentType" required="false" values="json|xml|text|binary"/>
            <param name="collection" alias="collection[]" repeatable="true" required="false"/>
            <param name="property" alias="property[]" repeatable="true" required="false"/>
            <param name="permission" alias="permission[]" repeatable="true" required="false"/>
            <param name="quality" required="false"/>
			<param name="language" required="false" />
            <param name="contentForBinary" required="false"/>
            <param name="extractMetadata" required="false" as="boolean" default="true"/>
            <param name="extractContent" required="false" as="boolean" default="true"/>
            <param name="applyTransform" required="false"/>
            <param name="respondWithContent" required="false" as="boolean" default="false"/>
            <param name="repair" required="false" as="boolean" default="false"/>
        </http>
        <http method="DELETE">
            <param name="stringQuery" required="false"/>
            <param name="structuredQuery" required="false"/>
            <param name="bulkDelete" required="false" as="boolean" default="false"/>
            <param name="include" alias="include[]" repeatable="true" required="false"/>
            <param name="limit" required="false" as="integer"/>
            <param name="outputFormat" required="false" values="json|xml"/>
        </http>
    </request>

    <!-- Search endpoint -->
    <request uri="^/search/?$" endpoint="/corona/search.xqy" user-params="allow">
        <param name="txid" required="false"/>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="orderBy" required="false"/>
        <param name="orderDirection" required="false" default="descending"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="length" required="false" as="positiveInteger" default="10"/>
        <param name="qualityWeight" required="false" as="decimal" default="1.0"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="filtered" required="false" default="false" as="boolean"/>
        <param name="language" required="false" />
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false" values="json|xml"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Key value queryies -->
    <request uri="^/kvquery/?$" endpoint="/corona/kvquery.xqy" user-params="allow">
        <param name="txid" required="false"/>
        <param name="key" required="false"/>
        <param name="element" required="false"/>
        <param name="attribute" required="false"/>
        <param name="property" required="false"/>
        <param name="value" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="length" required="false" as="positiveInteger" default="1"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false" values="json|xml"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Facets -->
    <request uri="^/facet/([A-Za-z0-9_\-,]+)/?$" endpoint="/corona/facet.xqy" user-params="allow">
        <param name="txid" required="false"/>
        <uri-param name="facets">$1</uri-param>
        <param name="stringQuery" required="false"/>
        <param name="structuredQuery" required="false"/>
        <param name="language" required="false" />
        <param name="limit" as="integer" default="25" required="false"/>
        <param name="order" required="false" default="frequency" values="descending|ascending|frequency"/>
        <param name="frequency" required="false" default="document" values="document|key"/>
        <param name="includeAllValues" required="false" default="no" values="no|yes"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
        <param name="outputFormat" required="false"  values="xml|json"/>
        <http method="POST"/>
        <http method="GET"/>
    </request>

    <!-- Transaction management -->
    <request uri="^/transaction/(status|create|commit|rollback)/?$" endpoint="/corona/transaction.xqy" user-params="allow">
        <uri-param name="action">$1</uri-param>
        <param name="txid" required="false"/>
        <param name="outputFormat" required="false" values="xml|json"/>
        <param name="timeLimit" required="false" as="decimal"/>
        <http method="GET"/>
        <http method="POST"/>
    </request>

    <!-- Named query management -->
    <request uri="^/(namedquery|namedquery/([^/]+))/?$" endpoint="/corona/named-query.xqy" user-params="allow">
        <uri-param name="name">$2</uri-param>
        <param name="outputFormat" required="false"  values="xml|json"/>
        <http method="GET">
            <param name="property" required="false"/>
            <param name="value" required="false"/>
            <param name="collection" alias="collection[]" required="false" repeatable="true"/>
            <param name="matchingDoc" alias="matchingDoc[]" required="false" repeatable="true"/>
            <param name="start" required="false" as="positiveInteger" default="1"/>
            <param name="length" required="false" as="positiveInteger" default="1"/>
        </http>
        <http method="POST">
            <param name="description" required="false"/>
            <param name="stringQuery" required="false"/>
            <param name="structuredQuery" required="false"/>
            <param name="collection" alias="collection[]" repeatable="true" required="false"/>
            <param name="property" alias="property[]" repeatable="true" required="false"/>
            <param name="permission" alias="permission[]" repeatable="true" required="false"/>
        </http>
        <http method="DELETE"/>
    </request>


    <!-- Index management -->

    <request uri="^/manage/?$" endpoint="/corona/manage/summary.xqy" user-params="allow">
        <http method="GET"/>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(ranges|range/([A-Za-z0-9_-]+))/?$" endpoint="/corona/manage/range.xqy" user-params="allow">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="type" required="true"/>
            <param name="collation" required="false"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(bucketedranges|bucketedrange/([A-Za-z0-9_-]+))/?$" endpoint="/corona/manage/bucketedrange.xqy" user-params="allow">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="type" required="true"/>
            <param name="buckets" required="false"/>
            <param name="bucketInterval" required="false"/>
            <param name="startingAt" required="false"/>
            <param name="stoppingAt" required="false"/>
            <param name="format" required="false"/>
            <param name="firstFormat" required="false"/>
            <param name="lastFormat" required="false"/>
            <param name="collation" required="false"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(geospatials|geospatial/([A-Za-z0-9_-]+))/?$" endpoint="/corona/manage/geo.xqy" user-params="allow">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="parentKey" required="false"/>
            <param name="parentElement" required="false"/>
            <param name="latKey" required="false"/>
            <param name="longKey" required="false"/>
            <param name="latElement" required="false"/>
            <param name="longElement" required="false"/>
            <param name="latAttribute" required="false"/>
            <param name="longAttribute" required="false"/>
            <param name="coordinateSystem" required="false" default="wgs84"/>
            <param name="comesFirst" required="false" default="latitude"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(namespaces|namespace/([^/]+))/?$" endpoint="/corona/manage/namespace.xqy" user-params="allow">
        <uri-param name="prefix" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="uri" required="true"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(transformers|transformer/([^/]+))/?$" endpoint="/corona/manage/transformer.xqy" user-params="allow">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="PUT"/>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(place|places|place/([^/]+))/?$" endpoint="/corona/manage/places.xqy" user-params="allow">
        <uri-param name="scope" as="string">$1</uri-param>
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="PUT">
            <param name="mode" required="false" default="textContains"/>
        </http>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="place" required="false"/>
            <param name="type" required="false" default="include"/>
            <param name="weight" required="false" default="1.0" as="decimal"/>
        </http>
        <http method="DELETE">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="place" required="false"/>
            <param name="type" required="false" default="include"/>
        </http>
    </request>

    <request uri="^/manage/(namedqueryprefixes|namedqueryprefix/([^/]+))/?$" endpoint="/corona/manage/namedqueryprefix.xqy" user-params="allow">
        <uri-param name="prefix" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST"/>
        <http method="DELETE"/>
    </request>

    <!-- Schema management -->
    <request uri="^/manage/(schemas|schema)/?$" endpoint="/corona/manage/schemas.xqy" user-params="allow">
        <param name="uri" required="false"/>
        <http method="GET"/>
        <http method="PUT"/>
        <http method="DELETE"/>
    </request>

    <!-- Environment variables -->
    <request uri="^/manage/(env|env/([^/]+))/?$" endpoint="/corona/manage/env.xqy" user-params="allow">
        <uri-param name="name" as="string">$2</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="value" required="true"/>
	    </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/config/?$" endpoint="/config/site/index.xqy" user-params="allow"/>
    <request uri="^/config/search/?$" endpoint="/config/site/search.xqy" user-params="allow"/>
    <request uri="^/config/namespaces/?$" endpoint="/config/site/namespaces.xqy" user-params="allow"/>
    <request uri="^/config/transformers/?$" endpoint="/config/site/transformers.xqy" user-params="allow"/>
    <request uri="^/config/env/?$" endpoint="/config/site/env.xqy" user-params="allow"/>

    <request uri="^/config/setup/?$" endpoint="/config/setup.xqy" user-params="allow">
        <http method="GET"/>
        <http method="POST"/>
    </request>

</options>;

declare function endpoints:options(
) as element(rest:options)
{
    $ENDPOINTS
};

declare function endpoints:request(
    $module as xs:string
) as element(rest:request)?
{
    ($ENDPOINTS/rest:request[@endpoint = $module])[1]
};
