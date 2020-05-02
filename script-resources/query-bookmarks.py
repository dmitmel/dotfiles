# helper script for query-bookmarks.sh
# useful links:
# https://stackoverflow.com/a/740183/12005228
# https://wiki.mozilla.org/Places:BookmarksComments

import sqlite3
import sys

db = sqlite3.connect(sys.argv[1])

urls = {}
for urlId, url, in db.execute("SELECT id, url FROM urls"):
    urls[urlId] = url

for title, urlId, keyword, in db.execute(
    "SELECT title, urlId, keyword FROM items WHERE kind = 1 AND validity AND NOT isDeleted"
):
    url = urls[urlId]
    print("{}\t{}".format(title, url))
    if keyword is not None:
        print("{}\t{}".format(keyword, url))
