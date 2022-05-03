from dataclasses import dataclass
from typing import List


######################################################################
# Pin List Data Structure
######################################################################
@dataclass
class PinRegions:
    regionId: str
    currentReplicationCount: int
    desiredReplicationCount: int


@dataclass
class PinMetaData:
    name: str
    keyvalues: None


@dataclass
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

    @staticmethod
    def extract_hash_pin(rows: List[PinRow]):
        return [row.ipfs_pin_hash for row in rows], rows

    def filter_active_pins(self):
        return self.extract_hash_pin(
            [PinRow(**row) for row in self.rows if PinRow(**row).date_unpinned is None]
        )


######################################################################
# Pin Creation
######################################################################

@dataclass
class PinCreation:
    IpfsHash: str
    PinSize: int
    Timestamp: str

