from IService import IService
from typing import List
import logging

logger = logging.getLogger(__name__)


class DynamoState(IService):
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

