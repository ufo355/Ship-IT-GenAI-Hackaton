import json
import boto3
import os


client = boto3.client('lexv2-runtime')

def lambda_handler(event, context):
    try:
        body = event.get('body')
        body_dict = json.loads(body)
        userId = body_dict.get('sender')

        user_message = body_dict.get('message')
        
        botId = os.environ['BOT_ID']
        botAliasId = os.environ['BOT_ALIAS_ID']
        localeId = os.environ['LOCALE_ID']
        
        response = client.recognize_text(
            botId=botId,
            botAliasId=botAliasId,
            localeId=localeId,
            sessionId=userId,
            text=user_message
        )

        messages = response.get('messages', [])
        lex_response = [json.loads(mes['content']) for mes in messages]

        return {
            'statusCode': 200,
            'body': json.dumps(lex_response),
            "headers": {
                "content-type": "application/json",
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            }           
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }