import json

def lambda_handler(event, context):
    # Add proper CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST',
        'Content-Type': 'application/json'
    }
    
    # Handle OPTIONS request
    if event['requestContext']['http']['method'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        body = json.loads(event['body'])
        name = body.get('name', 'World')
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': f'Hello, {name}!'
            })
        }
    except Exception as e:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({
                'error': str(e)
            })
        }
