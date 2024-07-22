import boto3
import json
import random

import logging
logger = logging.getLogger()
logger.setLevel("INFO")

lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
  try:
    print("Incoming event: ", event)
    intent = event['interpretations'][0]['intent']['name']
    match intent:
      case "Introduction":
        return introduction_response_custom(intent)
      case "SetContextToPets":
        return set_context_pets(intent)
      case "SetContextToKnowledgeBase":
        return set_context_knowledge_base(intent)
      case "PetsQuery":
        return pets_query(event)
      case "KnowledgeBaseQuery":
        return knowledge_base_query(event)
      case "FallbackIntent":
        return fallback_response_custom(intent)
      case _:
        return coming_soon_response_custom(intent)
  except:
    return get_response_schema([{"contentType": "CustomPayload", "content": json.dumps({"text": f"Error from lambda, detected intent: {intent}"})}], intent)
  

def safe_get(slot, keys, default=None):
    for key in keys:
        try:
            slot = slot[key]
        except (TypeError, KeyError):
            return default
    return slot

def pets_query(event):
    intent = "PetsQuery"
    user_query = event.get("inputTranscript","")
    slots = event.get("interpretations")[0].get("intent").get("slots")
    pet_type = None
    if slots:
      pet_type = safe_get(slots, ["PetType", "value", "resolvedValues"], None)
      pet_type = pet_type[0] if pet_type else None

    payload = { "body": {
          "sender": "test_user",
          "message": user_query,
          "document": "pet"
    }}

    if pet_type:
      types_dict = {
        "pies": "dog",
        "kot": "cat"
      }
      payload["body"].update({"pet_type": types_dict.get(pet_type)})

    print("Wsyłam taki payload: ", payload)
    response = lambda_client.invoke(
        FunctionName = "rag-query-lambda",
        InvocationType = 'RequestResponse',
        Payload = json.dumps(payload)
    )
    response_json = json.loads(response["Payload"].read())
    body_content = json.loads(response_json['body'])[0]

    response_text = body_content['text']
    data_context = [{
        "image": context['metadata']['main_image_url'],
        "name":  context['metadata']['pet_name'],
        "ratings": 5.0,
        "title": context['metadata']['pet_name'],
        "url": context['metadata']['page_url']} for context in body_content['context']]

    if data_context:
      message_list = [
        {     
          'contentType': 'CustomPayload',
          'content': json.dumps({ "text": response_text})
        },
        {
          'contentType': 'CustomPayload',
          'content': json.dumps({ 
            "custom": {
              "payload": "cardsCarousel",
              "data": data_context
              }}
            )
          }
      ]
    else: 
        message_list = [
        {     
          'contentType': 'CustomPayload',
          'content': json.dumps({ "text": response_text})
        }
        ]
    return get_response_schema(message_list, intent)


def set_context_knowledge_base(intent):
  message_content = "Zadaj mi inne pytanie dotyczące adopcji zwierzaka 🏡"
  messages_list = [{"contentType": "CustomPayload", 
        "content": json.dumps({"text": message_content})}]
  return get_response_schema(messages_list, intent)

def set_context_pets(intent):
  message_content = "Opowiedz o swoim wymarzonym pupilu, a ja spróbuje znaleźć dla Ciebie odpowiednich kandydatów. Lub zapytaj o konkretne zwierzę"
  messages_list = [{"contentType": "CustomPayload", 
        "content": json.dumps({"text": message_content})}]
  return get_response_schema(messages_list, intent) 



def coming_soon_response_custom(intent):
  message_content = "Wkrótce..🐕"
  messages_list = [{"contentType": "CustomPayload", 
        "content": json.dumps({"text": message_content})}]
  return get_response_schema(messages_list, intent) 

def introduction_response_custom(intent):
  message_list = [
            {
              'contentType': 'CustomPayload',
              'content': json.dumps({ "text": 'Cześć, miłośniku zwierząt! 🦴🐶 Witamy w serdecznym świecie merdających ogonów i kojących mruczeń. Niezależnie od tego, czy jesteś tu, aby adoptować nowego, futrzastego członka rodziny, jako wolontariusz, czy po prostu chcesz się rozejrzeć, cieszymy się, że jesteś z nami. Gotowy, by znaleźć swojego nowego najlepszego przyjaciela? Zacznijmy merdać ogonami i poruszać wąsikami! Oto kilka aktywności, przy których mogę ci pomóc 🐾'})
            },
            {
              'contentType': 'CustomPayload',
              'content': json.dumps({ 
                "buttons": [
                    {
                        "title": "📋 Opisz zwierzaka",
                        "payload": "Opisz zwierzaka"
                    },
                    {
                        "title": "🔍 Znajdź idealnego zwierzaka",
                        "payload": "Znajdź idealnego zwierzaka"
                    },
                    {
                        "title": "🏠 Pytanie o adopcję",
                        "payload": "Pytanie o adopcję"
                    }
                  ]}
                )
              }
            ]
  return get_response_schema(message_list, intent) 

def knowledge_base_query(event):
  #TO DO
  pass

def fallback_response_custom():
  intent = "FallbackIntent"
  messages_list = [{"contentType": "CustomPayload", "content": json.dumps({"text": "Uppps, nie złapałem 🥎, czy możesz powtórzyć?"})}]
  return get_response_schema(messages_list, intent)

def get_response_schema(messages, intent):
  result = {"sessionState": {"dialogAction": {"type": "Close"}, "intent": { "confirmationState": "Confirmed", "name": intent, "state": "Fulfilled"}, }, "messages": messages}
  return result
