from connection.BackendConnection import (
    BackendConnection,
    S3State,
    DynamoState
)


def main():
    backend_connection = BackendConnection()
    backend_connection.set_backend_object(S3State)

    backend_connection.upload_data('dynamodb', )


if __name__ == "__main__":
    main()
