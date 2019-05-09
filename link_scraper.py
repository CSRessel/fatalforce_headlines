URL_2018 = "https://www.washingtonpost.com/graphics/2018/national/police-shootings-2018/"
FIELDS = ["state", "gender", "race", "age", "mental_illness", "gun", "body_cam", "fleeing"]
OUTFILE = "link_dataset.pickle"
TIMEOUT=10

import pdb
import pickle

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

option = webdriver.ChromeOptions()
option.add_argument(" - incognito")

browser = webdriver.Chrome(executable_path='/home/clifford/Documents/school/76385/chromedriver', options=option)

browser.get(URL_2018)
# Wait 10 seconds for page to load
timeout = 10
try:
    WebDriverWait(browser, timeout).until(EC.visibility_of_element_located((By.XPATH, "//div[contains(@class, 'swiper-container')]")))
except TimeoutException:
    print("Timed out waiting for page to load")
    browser.quit()

next_btn = WebDriverWait(browser, TIMEOUT / 2).until(EC.element_to_be_clickable((By.XPATH, "//div[contains(@class, 'wp-swiper-button-next')]")))

dataset = []

while next_btn:
    name = browser.find_element_by_class_name("detailsName").text
    # div.swiper-slide-active / div.detailsShell / div.detailsCurr / div.detailsStats / p
    stats = [e.text for e in browser.find_elements_by_xpath("//div[@class='swiper-slide swiper-slide-active']//div[@class='detailsStats']/p")]
    # div.swiper-slide-active / div.detailsShell / div.detailsCurr / div.detailsSources / a
    srces = [e.get_attribute("href") for e in browser.find_elements_by_xpath("//div[@class='swiper-slide swiper-slide-active']//div[@class='detailsSources']/a")]

    for src in srces:
        datapoint = {}
        datapoint.update(zip(FIELDS, stats))
        datapoint["name"] = name
        datapoint["link"] = src

        dataset.append(datapoint)
        print(str(len(dataset)) + "... " + datapoint["name"])

    next_btn.click()
    try:
        next_btn = WebDriverWait(browser, timeout).until(EC.element_to_be_clickable((By.XPATH, "//div[@class='wp-swiper-button wp-swiper-button-next']")))
    except TimeoutException:
        browser.quit()
        break

with open(OUTFILE, 'wb') as fp:
    pickle.dump(dataset, fp)

with open("link_dataset.csv", 'w') as outf:
    for dp in dataset:
        outf.write(",".join([b for a,b in sorted(list(dp.items()))]) + "\n")
