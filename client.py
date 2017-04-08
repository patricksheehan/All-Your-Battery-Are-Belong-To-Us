import math
import requests
from datetime import time as timestamp_g, datetime
import time

charging = True

def ask_for_what_to_do(current_battery_level, curr_consumption, timestamp):
    global charging
    url = 'http://127.0.0.1:5000/info/' + str(current_battery_level) + '/' + str(curr_consumption) \
          + '/' + str(int(time.mktime(timestamp.timetuple())))
    response = requests.get(url)
    print "battery level: " + str(current_battery_level) + \
          "%, power consumption " + str(curr_consumption) + \
          "Watt/h, hour: " + str(timestamp.hour) + " [ request to cloud ] Asking to the cloud what is the next action, url: " + url
    body = response.json()
    if body['charge']:
        charging = True
        print "Charging my battery"
    else:
        charging = False
        print "Releasing enery from the battery"

def loop_forever():
    current_time = 14
    percentage = 90
    while 1:
        if charging:
            percentage += 4
        else:
            percentage -= 5
        if percentage>100:
            percentage=100

        current_time += 1
        current_time = current_time % 24

        my_time = datetime(datetime.now().year, datetime.now().month, datetime.now().day, current_time, 0, 0, 0)

        ask_for_what_to_do(percentage, 1300, my_time)
        try:
            time.sleep(2)
        except:
            continue


loop_forever()
