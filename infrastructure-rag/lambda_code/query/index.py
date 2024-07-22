import os
import boto3
import json
from botocore.exceptions import ClientError
from langchain.vectorstores.pgvector import PGVector
from langchain.embeddings import BedrockEmbeddings
from langchain.prompts import PromptTemplate
from langchain_core.prompts import ChatPromptTemplate

from langchain.chains import LLMChain
from langchain.llms.bedrock import Bedrock
from sql import SQLDocStore
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.retrievers import ParentDocumentRetriever
from langchain_community.document_transformers import DoctranTextTranslator
from langchain_core.documents import Document
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain

DATABASE        = os.environ['DATABASE']
USER            = os.environ['DATABASE_USER']
PORT            = os.environ['DATABASE_PORT']
HOST            = os.environ['RDS_PROXY_ENDPOINT']
REGION          = os.environ['REGION']
COLLECTION_NAME = os.environ['COLLECTION_NAME']
SECRET_NAME     = os.environ['SECRET_NAME']

secretsmanager = boto3.client('secretsmanager')

def get_secret():
    secret = secretsmanager.get_secret_value(SecretId=SECRET_NAME) 
    secret_json = json.loads(secret['SecretString'])
    try:
        secret = secretsmanager.get_secret_value(SecretId=SECRET_NAME) 
        secret_json = json.loads(secret['SecretString'])
        return secret_json.get("password")
    except ClientError as e:
        raise e

def get_bedrock_client():
    bedrock_client = boto3.client("bedrock-runtime", region_name=REGION)
    return bedrock_client
    
def create_bedrock_llm(bedrock_client, model_version_id):
    bedrock_llm = Bedrock(
        model_id=model_version_id, 
        client=bedrock_client,
        model_kwargs={'temperature': 0.5}
        )
    return bedrock_llm
    
def create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id):
    bedrock_embeddings_client = BedrockEmbeddings(
        client=bedrock_client,
        model_id=bedrock_embedding_model_id)
    return bedrock_embeddings_client

bedrock_client = get_bedrock_client()
password = get_secret()
bedrock_llm = create_bedrock_llm(bedrock_client, "anthropic.claude-v2:1")
bedrock_embeddings_client = create_langchain_vector_embedding_using_bedrock(bedrock_client, "amazon.titan-embed-text-v1")

CONNECTION_STRING = PGVector.connection_string_from_db_params(
    driver="psycopg2",
    host=HOST,
    port=int(PORT),
    database=DATABASE,
    user=USER,
    password=get_secret(),
)

client_pgvector = PGVector(connection_string=CONNECTION_STRING, embedding_function=bedrock_embeddings_client, collection_name=COLLECTION_NAME)
store = SQLDocStore(
    collection_name="parent_documents",
    connection_string=CONNECTION_STRING,
)

child_splitter = RecursiveCharacterTextSplitter(
        chunk_size=200,
        chunk_overlap=20,
        length_function=len,
        is_separator_regex=False,
)

def lambda_handler(event, context):
    body = event.get("body")

    question = body.get("message")
    sender = body.get("sender")
    document_type = body.get("document")
    pet_name = body.get("pet_name")
    pet_type = body.get("pet_type")

    filters = {"document_type": document_type}

    if pet_name:
        filters.update({"pet_name": pet_name})
    if pet_type:
        filters.update({"pet_type": pet_type})

    # transform_prompt = PromptTemplate(
    #     input_variables=["query"],
    #     template='''Przekształć zapytanie tak, żeby było lepszą frazą dla wyszukiwarki. Usuń wszelkie zbędne informacje z zapytania takie jak: "szukaj", "zastanam się jak", "znajdź mi".
    #                 Nie zaczynaj odpowiedzi od słów "Poprawione zapytanie: ", "odpowiedź: " i podobnych. 
    #                 Zapytanie: {query}
    #                 Poprawione zapytanie:'''
    # )

    # transform_chain = LLMChain(llm=bedrock_llm, prompt=transform_prompt)
    # transformed_query = transform_chain.run({"query": question})

    retriever = ParentDocumentRetriever(
            vectorstore=client_pgvector,
            docstore=store,
            child_splitter=child_splitter,
            search_kwargs={"k": 5, "filter": filters}
    )
    
    # print("Przekształcone zapytanie: ", transformed_query)
    source_documents = retriever.get_relevant_documents(question)
    context = [doc.page_content for doc in source_documents][:3]
    answer_prompt = ChatPromptTemplate.from_template("""Jesteś wirtualnym asystentem w schronisku. Użyj poniższych informacji, aby odpowiedzieć na pytanie użytkownika.

        Kontekst: {context}
        Pytanie: {input}

        Jeśli w kontekście nie ma konkretnych informacji spróbuj wywnioskować odpowiedź.
        Nie zaczynaj odpowiedzi od słów "Na podstawie kontekstu" i podobnych.
        Pomocna odpowiedź:""")

    # Create a chain for answering the question
    answer_chain = LLMChain(llm=bedrock_llm, prompt=answer_prompt)
    answer_response = answer_chain.run({"input": question, "context": context})
    print("Odpowiedź: ", answer_response)

    context = [{"page_content": doc.page_content, "metadata": doc.metadata} for doc in source_documents]
    
    response_body = json.dumps([{"recipient_id": sender, "text": answer_response, "context": context}])
    
    return {
        "statusCode": 200,
        "statusDescription": "200 OK",
        "headers": {
            "Content-Type": "text/html"
        },
        "body": response_body
    }

    