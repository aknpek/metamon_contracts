from typing import Dict, Union, Any
from connection.IService import IService

import logging
logger = logging.getLogger(__name__)


class BackendConnection:
    backend_handler: Dict[str, IService] = {}
    instance: Any

    def __init__(self, service: Any, app_dev: bool = True):
        self.instance = service(app_dev)

    def set_backend_object(self, backend_handler: IService, resource: str, **kwargs):
        self.instance._get_connected(resource=resource, **kwargs)
        self.backend_handler[resource] = backend_handler

    def upload_data(self, resource: str, **kwargs):
        return self.backend_handler[resource].upload(connection=self.instance.connections[resource], **kwargs)

    def download_data(self, resource: str, **kwargs):
        return self.backend_handler[resource].download(connection=self.instance.connections[resource], **kwargs)

    def get_data(self, resource: str, **kwargs):
        return self.backend_handler[resource].get(connection=self.instance.connections[resource], **kwargs)

    def remove_data(self, resource: str, **kwargs):
        return self.backend_handler[resource].remove(connection=self.instance.connections[resource], **kwargs)
