from dataclasses import dataclass
from typing import List


######################################################################
# Pin List Data Structure
######################################################################
class PinRegions:
    regionId: str
    currentReplicationCount: int
    desiredReplicationCount: int


class PinMetaData:
    name: str
    keyvalues: None


class PinRow:
    id: str
    ipfs_pin_hash: str
    size: int
    user_id: str
    date_pinned: str
    date_unpinned: str
    metadata: PinMetaData
    regions: List[PinRegions]


@dataclass
class PinList:
    count: int
    rows: List[PinRow]

    def filter_active(self):
        pass


######################################################################
# Pin List Data Structure
######################################################################
