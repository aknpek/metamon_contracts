from connection.IService import IService
from typing import List, Dict
import logging
import boto3
import os


logger = logging.getLogger(__name__)


class DynamoState(IService):
    connections = None

    def upload(
            self,
            records: List[dict],
            table: str,
            resource: str = "dynamodb",
    ):
        try:
            table = self.connections[resource].Table(table)
            table.put_item(Item=records)

        except Exception as exception:
            logger.info(f'{exception}')

    def download(self):
        pass


class S3State(IService):
    def upload(
            self,
            path_s3: str,
            bucket_name: str,
            local_file_path: str,
            connection
    ):
        try:
            connection.upload_file(local_file_path, bucket_name, path_s3)

        except Exception as exception:
            logger.info(f'{exception}')

    def download(
            self,
            path_s3: str,
            bucket_name: str,
            file_name: str,
            connection
    ):
        try:
            connection.download_file(bucket_name, path_s3, file_name)

        except Exception as exception:
            logger.info(f'{exception}')


class ConnectAws:
    connections: Dict[str, boto3.resource] = {}
    session: boto3.Session

    def __init__(self, app_dev):
        self._init_connection(app_dev)

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
