if(typeof corona == "undefined" || !corona) {
    corona = {};
}

corona.dates = [
    {
        "string": "2011-07-07T11:05:42-07:00",
        "value": "2011-07-07T11:05:42-07:00"
    },
    {
        "string": "Thu Jul 07 2011 11:05:42 GMT-0700 (PDT)",
        "value": "2011-07-07T11:05:42-07:00"
    },
    {
        "string": "30 Jun 2006 09:39:08 -0500",
        "value": "2006-06-30T09:39:08-05:00"
    },
    {
        "string": "Apr 16 13:49:06 2003 +0200",
        "value": "2003-04-16T13:49:06+02:00"
    },
    {
        "string": "Aug 04 11:44:58 EDT 2003",
        "value": "2003-08-04T11:44:58-04:00"
    },
    {
        "string": "4 Jan 98 0:41 EDT",
        "value": "1998-01-04T00:41:00-04:00"
    },
    {
        "string": "25-Oct-2004 17:06:46 -0500",
        "value": "2004-10-25T17:06:46-05:00"
    },
    {
        "string": "Mon, 23 Sep 0102 23:14:26 +0900",
        "value": "2002-09-23T23:14:26+09:00"
    },
    {
        "string": "2011-07-07",
        "value": "2011-07-07T00:00:00-07:00"
    },
    {
        "string": "08-20-2007",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "08-20-07",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "2007/08/20",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "08/20/2007",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "08/20/07",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "20070820",
        "value": "2007-08-20T00:00:00-07:00"
    },
    {
        "string": "December 20, 2005",
        "value": "2005-12-20T00:00:00-07:00"
    },
    {
        "string": "Dec 20th, 2005",
        "value": "2005-12-20T00:00:00-07:00"
    },
    {
        "string": "September 1st, 2007",
        "value": "2007-09-01T00:00:00-07:00"
    }
];

$(document).ready(function() {
    module("Dates");
    for (var i = 0; i < corona.dates.length; i += 1) {
        corona.jsonFromServerTest(corona.dates[i]);
    }
});


corona.jsonFromServer = function(test, success, error) {
    asyncTest("Parsing: " + test.string, function() {
        $.ajax({
            url: '/test/xq/parsedate.xqy',
            data: {"date": test.string},
            method: 'GET',
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

corona.jsonFromServerTest = function(test) {
    corona.jsonFromServer(test,
        function(data, t, j) {
            equals(data, test.value, "Parsed date doesn't match");
        },
        function(j, t, e) { ok(false, e); console.log(e); } 
    );
};
