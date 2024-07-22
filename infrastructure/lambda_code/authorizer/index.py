import json
import jwt
import os
import boto3
from botocore.exceptions import ClientError

SECRET_MANAGER = os.environ['SECRET_MANAGER']

def get_secret():

    secret_name = SECRET_MANAGER
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = json.loads(get_secret_value_response['SecretString'])
    return secret.get("JWT_SECRET")

SECRET = get_secret()

def lambda_handler(event, context):
    response = {
        "isAuthorized": False,
        "context": {
            "stringKey": "value",
            "numberKey": 1,
            "booleanKey": True,
            "arrayKey": [],
            "mapKey": {}
        }
    }
    try:
        token = event['queryStringParameters']['token']
        validation_result = validate_jwt(token, SECRET)
        if validation_result:
            print('authorized')
            response = {
                "isAuthorized": True,
                "context": {
                    "stringKey": "value",
                    "numberKey": 1,
                    "booleanKey": True,
                    "arrayKey": [],
                    "mapKey": {}
                }
            }
            return response
    except jwt.ExpiredSignatureError as error:
        print(error)
    except jwt.InvalidTokenError as error:
        print(error)
    except Exception as error:
        print(error)
    return response
    
def validate_jwt(token, secret):
    try:
        decoded_token = jwt.decode(token, secret, algorithms=['HS512'])
        return decoded_token
    except jwt.ExpiredSignatureError as e:
        raise e 
    except jwt.InvalidTokenError as e:
        raise e
    except Exception as e:
        raise e