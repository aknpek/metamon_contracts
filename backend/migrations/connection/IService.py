from abc import ABC, abstractmethod


class IService(ABC):
    @abstractmethod
    def download(self, **kwargs):
        """Downloads data"""

    @abstractmethod
    def upload(self, **kwargs):
        """Uploads data"""
