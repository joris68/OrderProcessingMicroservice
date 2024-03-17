import json
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    for record in event['Records']:
        message_body = record['body']
        
        # Log the message body
        logger.info(f"Received Order: {message_body}")
    
    # Return a response
    return {
        'statusCode': 200,
        'body': json.dumps('Order processed successfully!')
    }