from typing import Dict
from IService import IService

import logging
import boto3
import os

logger = logging.getLogger(__name__)


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


class BackendConnection(ConnectAws):
    backend_handler: Dict[str, IService] = {}

    def __init__(self, app_dev: bool = True):
        super().__init__(app_dev=app_dev)

    def set_backend_object(self, resource: str, region: str, backend_handler: IService, service: str ="Aws"):
        if service == "Aws":
            self._get_connected(resource=resource, aws_region=region)

        self.backend_handler[resource] = backend_handler.__init__()

    def upload_data(self, resource: str, **kwargs):
        self.backend_handler[resource].upload(connection=self.connections[resource], **kwargs)

    def download_data(self, resource: str, **kwargs):
        self.backend_handler[resource].download(connection=self.connections[resource], **kwargs)
