import boto3
import os
import json
from sql import SQLDocStore
from botocore.exceptions import ClientError
from langchain.vectorstores.pgvector import PGVector
from langchain.embeddings import BedrockEmbeddings
from langchain.docstore.document import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import AmazonTextractPDFLoader
from langchain.retrievers import ParentDocumentRetriever

DATABASE        = os.environ['DATABASE']
USER            = os.environ['DATABASE_USER']
PORT            = os.environ['DATABASE_PORT']
HOST            = os.environ['RDS_PROXY_ENDPOINT']
REGION          = os.environ['REGION']
BUCKET_NAME     = os.environ['BUCKET_NAME']
COLLECTION_NAME = os.environ['COLLECTION_NAME']
SECRET_NAME     = os.environ['SECRET_NAME']


s3 = boto3.client('s3')
bedrock_client = boto3.client("bedrock-runtime", region_name=REGION)
textract_client = boto3.client("textract", region_name=REGION)

def get_secret():

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=REGION
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=SECRET_NAME
        )
    except ClientError as e:
        raise e

    secret = get_secret_value_response['SecretString']
    res = json.loads(secret)
    return res.get("password")

def handle_pdf(file_key, bucket_name):
    print(f"Handling PDF file: {file_key}")
    object_adress = "s3://"+bucket_name+"/"+file_key
    loader = AmazonTextractPDFLoader(object_adress, client=textract_client)
    documents = loader.load()
    for document in documents:
        document.metadata.update({"document_type": "adoption_information"})
    return documents

def handle_json(file_key, bucket_name):
    print(f"Handling JSON file: {file_key}")
    
    # Get the file contents from S3
    s3_response = s3.get_object(Bucket=bucket_name, Key=file_key)
    json_data = json.loads(s3_response['Body'].read().decode('utf-8'))

    docs = []
    for pet_obj in json_data:
        docs.append(Document(page_content=pet_obj['content'], metadata=pet_obj['metadata']))
    return docs

def handle_other(file_key, bucket_name):
    print(f"Handling other file: {file_key}")
    return []

doc_extracters = {
    ".pdf": handle_pdf,
    ".json": handle_json,
}

def categorize_and_handle_files(file_key, bucket_name):
    response = s3.list_objects_v2(Bucket=bucket_name)
    _, ext = os.path.splitext(file_key)

    doc_extracter = doc_extracters.get(ext, handle_other)
    docs = doc_extracter(file_key, bucket_name)
        
    return docs


def create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id):
    bedrock_embeddings_client = BedrockEmbeddings(
        client=bedrock_client,
        model_id=bedrock_embedding_model_id)
    return bedrock_embeddings_client

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

parent_retriever = ParentDocumentRetriever(
    vectorstore=client_pgvector,
    docstore=store,
    child_splitter=child_splitter,
)


def lambda_handler(event, context):
    try:
        s3.head_bucket(Bucket=BUCKET_NAME)
        file_key = event['Records'][0]['s3']['object']['key']
        
        documents = categorize_and_handle_files(file_key, BUCKET_NAME)
        
        parent_retriever.add_documents(documents)
    except Exception as e:
        print(e)
        
