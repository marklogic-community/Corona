xquery version "1.0-ml";

module namespace endpoints="http://marklogic.com/corona/endpoints";

import module namespace rest="http://marklogic.com/appservices/rest" at "/corona/lib/rest/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $endpoints:ENDPOINTS as element(rest:options) :=
<options xmlns="http://marklogic.com/appservices/rest">
    <!-- Manage documents in the database -->
    <request uri="^/(json|xml)/store(/.+)?$" endpoint="/corona/store.xqy" user-params="allow">
        <uri-param name="content-type">$1</uri-param>
        <uri-param name="uri" as="string">$2</uri-param>
        <http method="GET">
            <param name="q" required="false"/>
            <param name="customquery" required="false"/>
            <param name="extractPath" required="false"/>
            <param name="applyTransform" required="false"/>
            <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        </http>
        <http method="POST"/>
        <http method="PUT"/>
        <http method="DELETE">
            <param name="q" required="false"/>
            <param name="customquery" required="false"/>
            <param name="bulkDelete" required="false" as="boolean" default="false"/>
        </http>
    </request>

    <!-- Custom queries -->
    <request uri="^/(json|xml)/customquery(/)?$" endpoint="/corona/customquery.xqy">
        <uri-param name="content-type">$1</uri-param>
        <param name="q" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="end" required="false" as="positiveInteger"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <http method="GET"/>
        <http method="POST"/>
    </request>

    <!-- Query strings -->
    <request uri="^/(json|xml)/query(/)?$" endpoint="/corona/query.xqy">
        <uri-param name="content-type">$1</uri-param>
        <param name="q" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="end" required="false" as="positiveInteger"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
    </request>

    <!-- Key value queryies -->
    <request uri="^/(json|xml)/kvquery$" endpoint="/corona/kvquery.xqy">
        <uri-param name="content-type">$1</uri-param>
        <param name="key" required="false"/>
        <param name="element" required="false"/>
        <param name="attribute" required="false"/>
        <param name="property" required="false"/>
        <param name="value" required="false"/>
        <param name="start" required="false" as="positiveInteger" default="1"/>
        <param name="end" required="false" as="positiveInteger"/>
        <param name="include" alias="include[]" repeatable="true" required="false" default="content"/>
        <param name="extractPath" required="false"/>
        <param name="applyTransform" required="false"/>
        <param name="collection" alias="collection[]" required="false" repeatable="true"/>
        <param name="underDirectory" required="false"/>
        <param name="inDirectory" required="false"/>
    </request>

    <!-- Facets -->
    <request uri="^/(json|xml)/facet/([A-Za-z0-9_\-,]+)/?$" endpoint="/corona/facet.xqy">
        <uri-param name="content-type">$1</uri-param>
        <uri-param name="facets">$2</uri-param>
        <param name="q" required="false"/>
        <param name="customquery" required="false"/>
        <param name="limit" as="integer" default="25" required="false"/>
        <param name="order" required="false" default="frequency" values="descending|ascending|frequency"/>
        <param name="frequency" required="false" default="document" values="document|key"/>
        <param name="includeAllValues" required="false" default="no" values="no|yes"/>
        <param name="outputFormat" required="false"  values="xml|json"/>
    </request>

    <!-- Index management -->

    <request uri="^/manage(/)?$" endpoint="/corona/info.xqy" user-params="ignore"/>

    <request uri="^/manage/field/([A-Za-z0-9-]+)(/)?$" endpoint="/corona/manage/field.xqy">
        <uri-param name="name" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="includeKey" alias="includeKey[]" required="false" repeatable="true"/>
            <param name="excludeKey" alias="excludeKey[]" required="false" repeatable="true"/>
            <param name="includeElement" alias="includeElement[]" required="false" repeatable="true"/>
            <param name="excludeElement" alias="excludeElement[]" required="false" repeatable="true"/>
            <param name="mode" required="false" default="contains"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/range/([A-Za-z0-9_-]+)(/)?$" endpoint="/corona/manage/range.xqy">
        <uri-param name="name" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="type" required="true"/>
            <param name="operator" required="true"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/bucketedrange/([A-Za-z0-9_-]+)(/)?$" endpoint="/corona/manage/bucketedrange.xqy">
        <uri-param name="name" as="string">$1</uri-param>
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
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/map/([A-Za-z0-9_-]+)(/)?$" endpoint="/corona/manage/map.xqy">
        <uri-param name="name" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="key" required="false"/>
            <param name="element" required="false"/>
            <param name="attribute" required="false"/>
            <param name="mode" required="true"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/namespace/([^/]+)(/)?$" endpoint="/corona/manage/namespace.xqy">
        <uri-param name="prefix" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="POST">
            <param name="uri" required="true"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/(contentItem|contentItems)(/)?$" endpoint="/corona/manage/contentitems.xqy">
        <param name="key" required="false"/>
        <param name="element" required="false"/>
        <param name="attribute" required="false"/>
        <param name="field" required="false"/>
        <param name="mode" required="false" default="contains"/>
        <http method="GET"/>
        <http method="POST">
            <param name="weight" required="false" default="1.0" as="decimal"/>
        </http>
        <http method="DELETE"/>
    </request>

    <request uri="^/manage/transformer/([^/]+)(/)?$" endpoint="/corona/manage/transformer.xqy">
        <uri-param name="name" as="string">$1</uri-param>
        <http method="GET"/>
        <http method="PUT"/>
        <http method="DELETE"/>
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
