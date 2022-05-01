from connection.BackendConnection import (
    BackendConnection,
    S3State,
    DynamoState
)
from dotenv import load_dotenv


def main():
    load_dotenv()
    backend_connection = BackendConnection(app_dev=True)
    backend_connection.set_backend_object('s3', 'us-east-2', S3State)

    backend_connection.upload_data(
        path_s3="",
        bucket_name=str(),
        local_file_path=str(),
        resource="s3"
    )

    backend_connection.upload_data(
        path_s3="",

    )


if __name__ == "__main__":
    main()
