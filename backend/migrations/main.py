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

from dotenv import load_dotenv


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


def pinata_connection(backend_connection: BackendConnection):
    pinata_end_point = "https://api.pinata.cloud/data/pinList"

    backend_connection.set_backend_object(
        backend_handler=PinataService(),
        resource="pinata",
    )

    backend_connection.get_data(
        resource="pinata",
        url=pinata_end_point
    )


def main():
    load_dotenv()
    backend_connection = BackendConnection(app_dev=True, service=ConnectPinata)
    pinata_connection(backend_connection=backend_connection)


if __name__ == "__main__":
    main()
