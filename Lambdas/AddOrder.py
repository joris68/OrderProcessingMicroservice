import logging
import json
import boto3
import os
import traceback

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

     try:
          request_body = json.loads(event['body'])
          order_id = request_body['id']
     except KeyError:
         return {
             "statusCode": 400, "body": "Missing ID"
         }
     
    
    # Check if 'id' is present and not None
     if order_id is None:
        logging.error("Missing 'id' in the event.")
        return {"statusCode": 400, "body": "Missing value"}
    
    # Validate Order
     if not validate_order(order_id):
        logging.error(f"Invalid order ID: {order_id}")
        return {"statusCode": 400, "body": "Invalid order ID. Order ID must by bigger Zero"}
    
    # Placeholder for pushing to a queue (e.g., SQS)
     try:
          push_to_queue(json.dumps(request_body))
     except Exception as e:
         error_traceback = traceback.format_exc()
         return {"statusCode": 401, "body" : "Problems with Sending Messages to the Queue" + error_traceback}
         
    
        # 201 for POSTmethod success response
     return {"statusCode": 201, "body": "Order processed successfully."}


# just assume that ID must by > 0 and Integer
def validate_order(order_id) -> bool:
    if isinstance(order_id,  int):  
          return order_id > 0
    else:
        False
    
    
# "MessageDeduplicationId" not necassary bacause content-based content based deduplicatin enabled
def push_to_queue(request_body) -> None:
    sqs = boto3.client('sqs')
    queue_arn = os.getenv('Q_URL', 'default_value')
    response = sqs.send_message(
        QueueUrl=queue_arn,
        MessageBody=request_body,
        MessageGroupId='Order'
    )
    loggin
