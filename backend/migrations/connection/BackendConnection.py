from typing import Dict, List
from abc import ABC, abstractmethod
import logging
import boto3
import os

logger = logging.getLogger(__name__)


class IState(ABC):
    @abstractmethod
    def download(self, **kwargs):
        """Downloads data"""

    def upload(self, **kwargs):
        """Uploads data"""


class DynamoState(IState):
    connections = None

    def upload(
            self,
            records: List[dict],
            table: str,
            resource: str = "dynamodb"
    ):
        try:
            table = self.connections[resource].Table(table)
            table.put_item(Item=records)

        except Exception as exception:
            logger.info(f'{exception}')

    def download(self):
        pass


class S3State(IState):
    connections = None

    def upload(
            self,
            path_s3: str,
            bucket_name: str,
            local_file_path: str,
            resource: str = "s3"
    ):
        try:
            self.connections[resource].Bucket(bucket_name).upload_file(local_file_path, path_s3)

        except Exception as exception:
            logger.info(f'{exception}')

    def download(
            self
    ):
        pass


class ConnectAws:
    connections: Dict[str, boto3.resource]
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


class BackendConnection(ConnectAws):
    backend_handler: Dict[str, IState]

    def __init__(self, app_dev: bool = True):
        super().__init__(app_dev=app_dev)

    def set_backend_object(self, resource: str, region: str, backend_handler: IState):
        self._get_connected(resource=resource, aws_region=region)
        self.backend_handler[resource] = backend_handler

    def upload_data(self, resource: str, **kwargs):
        self.backend_handler[resource].upload(**kwargs)

    def download_data(self, resource: str, **kwargs):
        self.backend_handler[resource].download(**kwargs)
