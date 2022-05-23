from abc import ABC, abstractmethod


class IService(ABC):
    @abstractmethod
    def download(self, **kwargs):
        """Downloads data"""

    @abstractmethod
    def upload(self, **kwargs):
        """Uploads data"""

    @abstractmethod
    def get(self, **kwargs):
        """Gets data"""

    @abstractmethod
    def remove(self, **kwargs):
        """Remove data"""
