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
from typing import List, Dict
from helpers.data_files import read_json, write_json


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
        paths.extend(os.path.join(directory, file) for file in files_)
    return paths


def convert_to_files(path_to_file: str, removal: str = "./statics") -> List[str]:
    """Creates list of tuples to upload ipfs"""
    if os.path.isdir(path_to_file):
        all_files: List[str] = get_all_files(path_to_file)
        # TODO: file change based on the name
        files = [("file", (file.replace(removal, ""), open(file, "rb"))) for file in all_files]
    else:
        files = [("file", open(path_to_file, "rb"))]

    return files


def create_json_load(
        pinned_info: PinCreation,
        path_to_file: str,
        path_to_file_json: Dict[str, dict],
        away_api: str = "https://gateway.pinata.cloud/ipfs/"
    ):
    final_json = {}
    for key, value in path_to_file_json.items():
        if key == "items":
            mid_array = []
            for item in path_to_file_json[key]:
                mid_json_2 = {}
                for key_, value_ in item.items():
                    if key_ == "colorItems":
                        mid2_array = []
                        for item2 in item[key_]:
                            mid_json = {}
                            mini_title = str()
                            for key2, value2 in item2.items():
                                if key2 == "imageUrl":
                                    value2 = f'{away_api}/{pinned_info.IpfsHash}/{path_to_file}/{mini_title}.png'
                                elif key2 == "title":
                                    mini_title = value2
                                mid_json[key2] = value2
                            mid2_array.append(mid_json)
                        mid_json_2[key_] = mid2_array
                    else:
                        mid_json_2[key_] = value_

                mid_array.append(mid_json_2)
            final_json[key] = mid_array
        else:
            final_json[key] = value

    return final_json


def pinata_connection(backend_connection: BackendConnection):
    pinata_end_point = "https://api.pinata.cloud/data/pinList"

    path_to_file_1_ = "./statics/trainer/files/male/body/"
    path_to_file_1_json = "./statics/trainer/metadata/male/body/skin.json"

    path_to_file_2_ = "./statics/trainer/files/male/clothes/"
    path_to_file_2_json = "./statics/trainer/metadata/male/clothes/clothing.json"

    path_to_file_3_ = "./statics/trainer/files/male/eyes/"
    path_to_file_3_json = "./statics/trainer/metadata/male/eyes/eyes.json"

    path_to_file_4_ = "./statics/trainer/files/male/hair/bold-hair/"
    path_to_file_5_ = "./statics/trainer/files/male/hair/cap-hair/"
    path_to_file_6_ = "./statics/trainer/files/male/hair/order-hair/"
    path_to_file_7_ = "./statics/trainer/files/male/hair/spiky-hair/"
    path_to_file_8_ = "./statics/trainer/files/male/hair/tail-hair/"
    path_to_file_4_json = "./statics/trainer/metadata/male/hair/hair.json"

    path_to_file_1 = "./statics/trainer/files/female/body/"
    _path_to_file_1_json = "./statics/trainer/metadata/female/body/skin.json"

    path_to_file_2 = "./statics/trainer/files/female/clothes/"
    _path_to_file_2_json = "./statics/trainer/metadata/female/clothes/clothing.json"

    path_to_file_3 = "./statics/trainer/files/female/eyes/"
    _path_to_file_3_json = "./statics/trainer/metadata/female/eyes/eyes.json"

    path_to_file_4 = "./statics/trainer/files/female/hair/bold-hair/"
    path_to_file_5 = "./statics/trainer/files/female/hair/cap-hair/"
    path_to_file_6 = "./statics/trainer/files/female/hair/order-hair/"
    path_to_file_7 = "./statics/trainer/files/female/hair/spiky-hair/"
    path_to_file_8 = "./statics/trainer/files/female/hair/tail-hair/"
    _path_to_file_4_json = "./statics/trainer/metadata/female/hair/hair.json"

    paths = [
        path_to_file_1,
        path_to_file_2,
        path_to_file_3,
        path_to_file_4,
        path_to_file_5,
        path_to_file_6,
        path_to_file_7,
        path_to_file_8,
        path_to_file_1_,
        path_to_file_2_,
        path_to_file_3_,
        path_to_file_4_,
        path_to_file_5_,
        path_to_file_6_,
        path_to_file_7_,
        path_to_file_8_
    ]

    final_files = []
    for path in paths:
        final_files.extend(convert_to_files(
            path_to_file=path
        ))

    # backend_connection.set_backend_object(
    #     backend_handler=PinataService(),
    #     resource="pinata",
    # )

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
    #     path_to_file=final_files,
    #     url=pinata_end_point
    # )

    pinned_info = PinCreation(**{'IpfsHash': 'QmRZiUqCobqMLogFzFqm11XU1Z8Uge8VC6RWANAx52BiC9', 'PinSize': 1875981,
     'Timestamp': '2022-05-08T16:42:32.913Z'})

    pinata_json_file_1 = create_json_load(pinned_info, path_to_file_1_.replace("./statics/trainer", ""), read_json(path_to_file_1_json))
    pinata_json_file_2 = create_json_load(pinned_info, path_to_file_2_.replace("./statics/trainer", ""), read_json(path_to_file_2_json))
    pinata_json_file_3 = create_json_load(pinned_info, path_to_file_3_.replace("./statics/trainer", ""), read_json(path_to_file_3_json))
    pinata_json_file_4 = create_json_load(pinned_info, path_to_file_4_.replace("./statics/trainer", ""), read_json(path_to_file_4_json))

    m_pinata_json_file_1 = create_json_load(pinned_info, path_to_file_1.replace("./statics/trainer", ""), read_json(_path_to_file_1_json))
    m_pinata_json_file_2 = create_json_load(pinned_info, path_to_file_2.replace("./statics/trainer", ""), read_json(_path_to_file_2_json))
    m_pinata_json_file_3 = create_json_load(pinned_info, path_to_file_3.replace("./statics/trainer", ""), read_json(_path_to_file_3_json))
    m_pinata_json_file_4 = create_json_load(pinned_info, path_to_file_4.replace("./statics/trainer", ""), read_json(_path_to_file_4_json))

    male_char = [
        pinata_json_file_1,
        pinata_json_file_2,
        pinata_json_file_3,
        pinata_json_file_4,
    ]

    female_char = [
        m_pinata_json_file_1,
        m_pinata_json_file_2,
        m_pinata_json_file_3,
        m_pinata_json_file_4
    ]

    write_json("./statics/output/default_male_traits.json", male_char)

    write_json("./statics/output/default_female_traits.json", female_char)
    ############################
    # remove
    ############################
    pinata_end_point = 'https://api.pinata.cloud/pinning/removePinFromIPFS'
    #
    # removed_info = backend_connection.remove_data(
    #     hash=pinned_info.IpfsHash,
    #     resource="pinata",
    #     url=pinata_end_point
    # )


def main():
    load_dotenv()
    backend_connection = BackendConnection(app_dev=True, service=ConnectPinata)
    # pinata_connection(backend_connection=backend_connection)


if __name__ == "__main__":
    main()
