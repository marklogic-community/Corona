import sys
import shapefile
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

states = sf.records();
shapes = sf.shapes();

for x, state in enumerate(states):
	polygon = ""
	for point in shapes[x].points:
		polygon += "<point><latitude>" + str(point[1]) + "</latitude><longitude>" + str(point[0]) + "</longitude></point>"

	query = "<constraint><geo>" + sys.argv[4] + "</geo><region><polygon>" + polygon + "</polygon></region></constraint>"

	url ="/namedquery/state:" + state[5]
	params = urllib.urlencode({"description": state[6], "structuredQuery": query})

	print str(x + 1) + ": " + url

	conn.request("POST", url, params, {"Authorization": auth, "Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain"})
	response = conn.getresponse()

	if response.status == 400:
		continue

	# print response.status, response.reason
