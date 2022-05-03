import os.path

from connection.pinata.PinataServices import (
    ConnectPinata
)

from connection.BackendConnection import (
    BackendConnection,
)
from connection.aws.AwsServices import (
    S3State
)

from connection.pinata.PinataServices import (
    PinataService,
)

from connection.pinata.PinataData import (
    PinList,
    PinCreation
)

from dotenv import load_dotenv
from typing import List


def aws_connection(backend_connection: BackendConnection):
    backend_connection.set_backend_object('s3', 'us-east-2', S3State)

    backend_connection.upload_data(
        path_s3="",
        bucket_name=str(),
        local_file_path=str(),
        resource="s3"
    )

    backend_connection.upload_data(
        path_s3=""
    )


def get_all_files(directory: str) -> List[str]:
    """get a list of absolute paths to every file located in the directory"""
    paths: List[str] = []
    for root, dirs, files_ in os.walk(os.path.abspath(directory)):
        for file in files_:
            paths.append(os.path.join(root, file))
    return paths


def pinata_connection(backend_connection: BackendConnection):
    pinata_end_point = "https://api.pinata.cloud/data/pinList"
    path_to_file = "./statics/trainer/files/male/body/dark.png"

    # if os.path.isdir(path_to_file):
    #     all_files: List[str] = get_all_files(path_to_file)
    #     files = [("file", (file, open(file, "rb"))) for file in all_files]
    # else:
    files = [("file", open(path_to_file, "rb"))]

    backend_connection.set_backend_object(
        backend_handler=PinataService(),
        resource="pinata",
    )

    ############################
    # Get Info
    ############################
    # pin_list = backend_connection.get_data(
    #     resource="pinata",
    #     url=pinata_end_point
    # )
    # active_pins = PinList(count=pin_list['count'], rows=pin_list['rows']) \
    #     .filter_active_pins()

    ############################
    # Upload
    ############################
    # pinata_end_point = 'https://api.pinata.cloud/pinning/pinFileToIPFS'
    #
    # pinned_info = backend_connection.upload_data(
    #     resource='pinata',
    #     path_to_file=files,
    #     url=pinata_end_point
    # )

    ############################
    # remove
    ############################
    pinata_end_point = 'https://api.pinata.cloud/pinning/removePinFromIPFS'

    pin_created = PinCreation(**{'IpfsHash': 'QmcsG9oZcsgdXZKGHKKgZL6Jx3gGT4UCP4r7WgrEtfJbKw', 'PinSize': 49336,
                               'Timestamp': '2022-05-01T15:49:51.561Z'})

    removed_info = backend_connection.remove_data(
        hash=pin_created.IpfsHash,
        resource="pinata",
        url=pinata_end_point
    )


def main():
    load_dotenv()
    backend_connection = BackendConnection(app_dev=True, service=ConnectPinata)
    pinata_connection(backend_connection=backend_connection)


if __name__ == "__main__":
    main()
