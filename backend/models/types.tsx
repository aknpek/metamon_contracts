////////////////////////////////////////////////////////////
/// Character Creation Schema
////////////////////////////////////////////////////////////
/*
We are using this data within the character creation
pages
*/

type EachCharItem = {
  title: string;
  imageUrl: string;
  colorHash: string;
};

type CharItems = {
  shape: string;
  colorItems: EachCharItem[];
};

type CharacterItems = {
  title: string;
  items: CharItems[];
};

////////////////////////////////////////////////////////////
/// Item NFT Schema
////////////////////////////////////////////////////////////
/*
We are using this data within the item mint pages
*/
type EachItem = {
  id: number;
  itemType: string;
  price: number;
  totalNumber: number;
};

type Items = {
  items: EachItem[];
};

////////////////////////////////////////////////////////////
/// Web3 Item Contract Answer Schema
////////////////////////////////////////////////////////////
/*
We are using this data within the item mint pages,
however we will receive this data from the contract *balanceOf
*/
type EachItemMinted = {
  id: number;
  numberMinted: number;
};

type ItemMinted = {
  items: EachItemMinted[];
};
