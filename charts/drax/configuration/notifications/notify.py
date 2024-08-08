from confluent_kafka import Producer
from datetime import datetime
import json
import os


def new_kafka_producer():
    kafka_hostname = os.getenv("KAFKA_HOSTNAME")
    kafka_port = os.getenv("KAFKA_PORT")

    bootstrap_servers = f"{kafka_hostname}:{kafka_port}"

    producer_conf = {"bootstrap.servers": bootstrap_servers}
    producer = Producer(producer_conf)

    return producer


def new_json_message():
    now_epoch = datetime.now().timestamp()
    now_epoch_microseconds = int(now_epoch * 1000000)
    return {
        "event": {
            "commonEventHeader": {
                "domain": "stndDefined",
                "eventId": "stndDefined-dRAX-Accelleran-000001",
                "eventName": "stndDefined-dRAX-Accelleran",
                "lastEpochMicrosec": now_epoch_microseconds,
                "priority": "Normal",
                "reportingEntityName": "ACCdRAX",
                "sequence": 0,
                "sourceName": "ACCdRAX",
                "startEpochMicrosec": now_epoch_microseconds,
                "stndDefinedNamespace": "3GPP-FaultSupervision",
                "version": "4.1",
                "timeZoneOffset": "UTC+00:00",
                "vesEventListenerVersion": "7.2",
            },
            "stndDefinedFields": {
                "data": {
                    "href": 1,
                    "uri": "xyz",
                    "notificationId": "1",
                    "notificationType": "notifyNewAlarm",
                    "eventTime": "xyz",
                    "systemDN": "xyz",
                    "probableCause": "Installation/upgrade of Accelleran dRAX",
                    "perceivedSeverity": "Minor",
                    "rootCauseIndicator": "false",
                    "specificProblem": "7052",
                }
            },
            "stndDefinedFieldsVersion": "1.0",
        }
    }


def publish_message(producer_instance, topic_name, key, value):
    def delivery_report(err, msg):
        if err is not None:
            print(f"Message delivery failed: {err}")
        else:
            print(f"Message delivered to {msg.topic()} [{msg.partition()}]")

    try:
        producer_instance.produce(
            topic_name, key=key, value=value.encode("utf-8"), callback=delivery_report
        )
        producer_instance.poll(0)
    except Exception as ex:
        print(f"Exception while publishing message: {str(ex)}")


def main():
    producer = new_kafka_producer()
    topic = "accelleran.drax.5g.ric.o1.ves"

    json_message = new_json_message()
    publish_message(producer, topic, None, json.dumps(json_message))

    producer.flush()


if __name__ == "__main__":
    main()
