// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract WardrobePaymentSplitter is PaymentSplitter {

    constructor(address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable{

    }
}

/**

SHARE
[500,
167,
500,
167,
166,
100,
50,
25,
200,
200,
200,
125,
100,
100,
4800,
250,
125,
125,
50,
1000,
1000]


PARAMS:
[0xba4e61912077f86ebfe1d6dd4928cdffec1bc4d5,
0x66c8fc80810feff3e1f0f8b641f4d57c572677c7,
0xC44BE13D3b12d1b2A243B1bE4EEaAb0c8399b938,
0x5D8906c28a43bD2E99680b7552963d196602bE84,
0x899e509b3341501c051b4a7f2be69eda577a54b7,
0x346b3191d21c4eb34c22313b67aa4a26ba9ee772,
0x7382119ce57d37ad4f0d2ea5594d2776e53f2fe1,
0xa521e99e20c3e2cc76617df9281f73db09a2ec88,
0xA94173232c90C49B42C9E188e4cAfa16b7EAD937,
0xe39fBB044763a57ffb3b7fE85a23ceDBFc3d7606,
0x5061b574F87322Dd5BD0082a787cC46582F1307C,
0xf5a56D6FA99d55642274eDd566293974a641a3DB,
0x6b29E9889982bC2d2B052085bdb878c467F7527B,
0x7f9aBA2457fd67F298A17a62aC9fD2B4a6348f64,
0x277310Ae1bc191f1985d9E31485625486Edf6090,
0x82bF1ff71ba7b37c55450D88ea31BA26d7Bc3bcc,
0x97C5Bc183bafabd5100C234e32e2A9E0C3AFbAa7,
0x6b17bb77F8Bde7cBE21306BFB6E3969A9bA70841,
0x5C95A98c623bc5276B86ACa7D9E84d0E1b0116fe,
0x778341cFfb8C60217958Bd8B2B8a5139c686485a,
0xa80A2501dA8c8eeb7905acEd7082Cf705A944d56
]
**/