import base64
import io
import json
import os

import boto3
import requests

CF_ACCOUNT_ID = os.environ["CF_ACCOUNT_ID"]
CF_AUTH_TOKEN = os.environ["CF_AUTH_TOKEN"]
CF_MODEL = "@cf/black-forest-labs/flux-1-schnell"

AWS_ACCESS_KEY = os.environ["AWS_ACCESS_KEY"]
AWS_SECRET_KEY = os.environ["AWS_SECRET_KEY"]

S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
QUEUE_NAME_DONE_GENERATE = os.environ["QUEUE_NAME_DONE_GENERATE"]

URL = f'https://api.cloudflare.com/client/v4/accounts/{CF_ACCOUNT_ID}/ai/run/{CF_MODEL}'


# Yandex cloud function | Entrypoint
def handler(event, context):
    batch = event['messages']

    print("Start processing batch messages, size: ", len(batch))
    for message in batch:
        process_message(message['details']['message']['body'])

    return "OK"


def process_message(message: str):
    print("Processing message: ", message)
    parsed = parse_message(message)

    try:
        image_base64 = generate_image(parsed['prompt'])
        upload_file(parsed['id'], image_base64)
        send_done_message(parsed['id'], True)
    except Exception as ex:
        print(f'Failed to process message: {message}, error: {ex}')
        send_done_message(parsed['id'], False)


def parse_message(raw: str) -> dict[str, str]:
    return dict(kv.split('=', 1) for kv in raw.split('||'))


def generate_image(prompt: str) -> str:
    response = requests.post(
        URL,
        headers={'Authorization': 'Bearer ' + CF_AUTH_TOKEN},
        data=json.dumps({
            'prompt': prompt,
            'height': 1080,
            'width': 1920
        })
    )
    if not response.ok:
        raise RuntimeError('Failed to post cloudflare: ' + response.text)

    return response.json()['result']['image']


def upload_file(id: str, image_base64: str):
    s3_client = boto3.client(
        's3',
        endpoint_url='https://storage.yandexcloud.net',
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
    )
    file_bytes = base64.b64decode(image_base64)
    file_obj = io.BytesIO(file_bytes)

    s3_client.upload_fileobj(file_obj, S3_BUCKET_NAME, f'{id}.jpg')


def send_done_message(id_image: str, success: bool):
    sqs_client = boto3.client(
        'sqs',
        region_name='ru-central1',
        endpoint_url='https://message-queue.api.cloud.yandex.net',
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
    )

    queue_url = sqs_client.get_queue_url(QueueName=QUEUE_NAME_DONE_GENERATE).get('QueueUrl')

    sqs_client.send_message(
        QueueUrl=queue_url,
        MessageBody=f'id={id_image}||success={success}'.lower(),
    )
