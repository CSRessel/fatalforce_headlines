LINK_FILE = "link_dataset.pickle"
HEADLINE_FILE = "headline_dataset.pickle"
UNPROCESSED_FILE = "unprocessed_dataset.pickle"
TIMEOUT=10

import pdb
import pickle
import re
import requests

from lxml import html

with open(LINK_FILE, 'rb') as fp:
    dataset = pickle.load(fp)

headlined = []
unprocessed = []

for datapoint in dataset:
    url = "\t" + datapoint["link"]
    print(url)

    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'
    try:
        r = requests.get(url, headers={'User-Agent': user_agent}, timeout=TIMEOUT)
        tree = html.fromstring(r.content)
        h1s = [e.strip() for e in tree.xpath('//h1/text()')]

        # False Positives
        # "SIGN IN"
        # "40X.*"
        # "Access Denied"
        # "Subscribe to Daily Headlines"
        # "Subscribe to Breaking News"
        # "Connect. Discover. Share."
        # "Breaking & daily news emails"
        # "Page Not Found"
        # "Page No Longer Available"
        # "Server Error"
        # "Menu" "News" "Sections"
        # "Maine" "East Bay" "San Francisco" "South Bay" "Arkansas Blog"
        # "Scene and Heard: Scene's News Blog"
        # "Covering Prince George's County"

        # Potential False Negatives (length)
        # "'Don't let anybody forget it'"
        # "Friday Shooting Suspect Identified"
        # "Man shot by Casselberry police dies"
        # "KSP involved in deadly shooting"
        # "Man shot by police officers dies"
        # "Shooting investigation continues"

        headlines = list(filter(lambda x: len(x) > 0, h1s))
        if headlines:
            headline = headlines[0]

            if re.match(r"^(?:SIGN IN|40[0-9]{1}|Access Denied|Subscribe .+)$", headline) \
                    or re.match(r"^(?:Scene and Heard.+|Covering Prince George.+)$", headline) \
                    or len(headline) <= 28:
                print("skipped improper parse " + headline)
                unprocessed.append(datapoint)
                continue

            print(headline)

            with open("outfile.txt", "a") as outf:
                outf.write(headline + "\n")
            datapoint["headline"] = headline
            headlined.append(datapoint)
        else:
            print("could not find headline " + url)
            unprocessed.append(datapoint)
    except Exception as e:
        print("could not access " + url + " because " + str(e))
        unprocessed.append(datapoint)

with open(HEADLINE_FILE, 'wb') as fp:
    pickle.dump(headlined, fp)

with open(UNPROCESSED_FILE, 'wb') as fp:
    pickle.dump(unprocessed, fp)

with open("headline_dataset.csv", 'w') as outf:
    for dp in headlined:
        outf.write(",".join([b for a,b in sorted(list(dp.items()))]) + "\n")
with open("unprocessed_dataset.csv", 'w') as outf:
    for dp in unprocessed:
        outf.write(",".join([b for a,b in sorted(list(dp.items()))]) + "\n")
