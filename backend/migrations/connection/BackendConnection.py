from re import A
from typing import Dict, List
import logging
import boto3
import os


logger = logging.getLogger(__name__)


class DataUpload:
    def upload_to_dynamo(self, records: List[dict], table: str):
        try: 
            table = self.dynamodb_connection.Table(table)
            table.put_item(Item=records)
        
        except Exception as exception:
            logger.info(f'{exception}')
    
    def upload_to_s3(
            self, 
            path_s3: str, 
            bucket_name: str, 
            local_file_path: str,
        ):
        
        try: 
            if self.session:
                self.session.resource('s3').Bucket(bucket_name).upload_file(local_file_path, path_s3)

            else:
                boto3.resource('s3').Bucket(bucket_name).upload_file(local_file_path, path_s3)
                
        except Exception as exception:
            logger.info(f'{exception}')


class DataDownload:
    pass


class ConnectAws:
    connections: Dict[boto3.connections]
    session: boto3.Session
        
    def __init__(self, ):
        pass
    
    
    def _init_connection(self, app_dev: bool) -> None:
        if app_dev:
            try: 
                self.session = boto3.Session(
                    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
                    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
                    # aws_session_token=os.getenv('AWS_SESSION_TOKEN')
                )    
            
            except Exception as exception:
                logger.info(f'Dev can not connect {exception}')
        
        else:
            logger.info('Boto3 Direct Connection')
            
    
    def _get_connected(self, resource: str, aws_region: str) -> None: 
        """Get connected to any AWS resource

        Args:
            resource (str): resource name
            aws_region (str): aws region
        """
        try: 
            if self.session:
                self.connections[resource] = self.session.client(resource, region_name=aws_region)
            else:
                self.connections[resource] = boto3.client(resource, region_name=aws_region)
        except Exception as exception:
            logger.info(f'Can not connect to backend {exception}')
            
        
    
class BackendConnection(ConnectAws, DataUpload):
    
    def __init__(self, app_dev: bool = True):
        super().__init__(app_dev=app_dev)
        
        
    def upload_data(self, ):
        pass
    
   