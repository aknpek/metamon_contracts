import os
import logging
import requests
from typing import Dict, Any
from connection.IService import IService

logger = logging.getLogger(__name__)

Headers = Dict[str, str]


class RestApiError:
    @staticmethod
    def error(response: requests.Response):
        logger.info(f'"status": {response.status_code}, "reason": {response.reason}, "text": {response.text}')


class PinataService(IService):
    def upload(
            self,
            url: str,
            path_to_file: str,
            connection: Headers
    ):
        response = requests.post(url=url, files=path_to_file, headers=connection)
        return response.json() if response.ok else RestApiError.error(response)

    def download(self):
        pass

    def get(self, url: str, connection: Headers):
        response = requests.get(url=url, headers=connection)
        return response.json() if response.ok else RestApiError.error(response)

    def remove(self, url: str, hash: str, connection: Headers):
        connection["Content-Type"] = "application/json"
        body = {"ipfs_pin_hash": hash}
        response = requests.post(url=url, json=body, headers=connection)
        return {"message": "Removed"} if response.ok else RestApiError.error(response)


class ConnectPinata:
    connections: Dict[str, Any] = {}
    session: Headers

    def __init__(self, app_dev: bool = True):
        self._init_connection(app_dev)

    def _init_connection(self, app_dev: bool):
        if app_dev:
            try:
                self.session = {
                    "pinata_api_key": os.getenv("PINATA_API_KEY"),
                    "pinata_secret_api_key": os.getenv("PINATA_API_SECRET")
                }
            except Exception as exception:
                logger.info(f'{exception}')

    def _get_connected(self, resource: str):
        try:
            if self.session:
                self.connections[resource] = self.session  # TODO: creates divergence, try think something out of this
            else:
                logger.info('Prod Mode')

        except Exception as exception:
            logger.info(f'{exception}')
