from datetime import time, datetime
from flask import Flask, jsonify

app = Flask(__name__)


def get_time_at_hour(hour):
    return datetime(datetime.now().year, datetime.now().month, datetime.now().day, hour, 0, 0, 0)


def charge_or_discharge(time_of_day, predicted_consumption=0, battery_level=0, predicted_production=0,
                        timeofuse_tariff=0):
    return battery_level < 100 and \
           not (get_time_at_hour(14) <= datetime.fromtimestamp(time_of_day) <= get_time_at_hour(19)) and \
           not (
           battery_level > 80 and get_time_at_hour(19) <= datetime.fromtimestamp(time_of_day) <= get_time_at_hour(23))


@app.route('/info/<float:level_battery>/<int:curr_consumption>/<int:time>', methods=['GET'])
def info(level_battery, curr_consumption, time):
    return jsonify({'charge': charge_or_discharge(time, curr_consumption, level_battery)})


if __name__ == '__main__':
    app.run()
