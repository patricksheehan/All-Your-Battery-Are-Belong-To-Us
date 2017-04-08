import csv
import requests
from datetime import datetime
import time

charging = True

def ask_for_what_to_do(current_battery_level, curr_consumption, timestamp):
    global charging
    url = 'http://127.0.0.1:5000/info/' + str(current_battery_level) + '/' + str(curr_consumption) \
          + '/' + str(int(time.mktime(timestamp.timetuple())))
    response = requests.get(url)

    print("battery level: {}\n% power consumption: {}\nWatt/h, hour: {}".format(current_battery_level, str(curr_consumption),
                                                                                timestamp.hour))
    body = response.json()
    if body['charge']:
        charging = True
        print("Charging my battery\n")
    else:
        charging = False
        print("Releasing energy from the battery\n")


def loop_forever():

    with open('usage_full_year_residential.csv', 'r') as f:
        next(f)
        measures = [measure for measure in csv.reader(f)]

    current_time = 12
    percentage = 90.

    for index, usage in measures:
        usage = float(usage)

        if charging:
            percentage += 0.5
        else:
            percentage -= usage
        if percentage > 100:
            percentage = 100.

        current_time += 1
        current_time = current_time % 24

        my_time = datetime(datetime.now().year, datetime.now().month, datetime.now().day, current_time, 0, 0, 0)

        ask_for_what_to_do(percentage, 1300, my_time)
        try:
            time.sleep(2)
        except:
            continue


loop_forever()
