import sys
import shapefile
import json
import httplib
import urllib
import base64

if (len(sys.argv) == 1):
    print "<folder> <port> <username>:<password> <geo index name>"
    sys.exit(0)

auth = 'Basic ' + base64.encodestring(sys.argv[3]).rstrip()

conn = httplib.HTTPConnection("localhost", sys.argv[2])
# conn.set_debuglevel(9)
sf = shapefile.Reader(sys.argv[1])

zips = sf.records();

for x, zipCode in enumerate(zips):
	polygon = []
	shape = sf.shape(x)
	for point in shape.points:
		polygon.append({"latitude": point[1], "longitude": point[0]})

	query = {"geo": sys.argv[4], "region": {"polygon":polygon}}

	url ="/namedquery/zip:" + zipCode[0]
	params = urllib.urlencode({"structuredQuery": json.dumps(query)})

	print str(x + 1) + ": " + url

	conn.request("POST", url, params, {"Authorization": auth, "Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain"})
	response = conn.getresponse()

	if response.status == 400:
		continue

	# print response.status, response.reason
