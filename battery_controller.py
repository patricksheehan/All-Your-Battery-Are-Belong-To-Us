from datetime import time


def charge_or_discharge(time_of_day, predicted_consumption=0, predicted_production=0, timeofuse_tariff=0):
    if time(14, 0) <= time_of_day <= time(19, 0):
        return 'discharge'
    else:
        return 'charge'
