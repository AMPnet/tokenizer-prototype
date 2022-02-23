export const Mumbai: TokenizerConfig = {
    issuerFactory: {
        basic: '0x463d65eba0efa397ad5d7Fa49f335DC44F124d03',
    },
    assetFactory: {
        basic: '0x5860e9a1BD5e310D306a9abC97181218374d6f7F',
        transferable: '0x05633b916E9ca43366F51FE7506126CeAe0Dc5d9',
        simple: '0x9d94eBdCd676B25EdABbaadf343140bf1Bf60e36',
    },
    cfManagerFactory: {
        basic: '0x5b14f62551FA82B8AeD78A72c8C483DAD5727C86',
        vesting: '0xe1284684E0f30089b114DFC141Ada9843c155f3f',
    },
    apxRegistry: {
        address: '0x93148Bd574232Acae13B12d6A3a1843109f5243b',
        owner: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857',
        assetManager: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857',
        priceManager: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857'
    },
    faucetService: {
        address: '0x00BeBf8FA0896a2743C3F1A0f43eAC2de0c149E0',
        owner: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857',
        callers: ['0xc06fcee3870a8115F5d3284121Fff1E049a39Ca4'],
        reward: '10000000000000000',
        threshold: '10000000000000000'
    },
    nameRegistry: {
        address: '0x254a38c1edF0448ecD9973B724FAABee2ad3Ffc0',
        owner: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857'
    },
    feeManager: {
        address: '0xC74f47030aedEBa155a65921E62e8B3C0Bf77140',
        owner: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857',
        treasury: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857'
    },
    walletApproverService: {
        address: '0xBbA256C3fC518f65974c3e84bB554757677d4c40',
        owner: '0x5013F6ce0f9Beb07Be528E408352D03f3FCa1857',
        callers: ['0x0382Fe477878c8C3807aB427D0DB282EFfa01CD6'],
        reward: '10000000000000000'
    },
    investService: '0x97B37a1F46b39cDD4F65aB54720e8eC8207be8E7',
    payoutManager: '0x06608Ae976424dbF97E5130E26637AFE96fD8C07',
    merkleTreePathValidator: '0x9982bb7bD0160B869D8E6Ca7559e53B01D2165eb',
    payoutService: '0x1b2F2e06feB844693cF27d181690f3212AE6c8d6',
    queryService: '0x743BFd8395b13157A3cE6b1D8c1aC172a20B4d4d',
    deployerService: '0x7EBb7d279Ff45Ba30698CC090a53c0EC05F89f81',
    emptyFactory: '0x3BE13506aF685EB2d2F6321700053f6395146522'
}

export const Matic: TokenizerConfig = {
    issuerFactory: {
        basic: '0x9DFC2e793a3e88ae61766aaC24F7167501953dC9',
    },
    assetFactory: {
        basic: '0xd129c487ea7A5B8583f742a6c3dD99617Bb23Bf6',
        transferable: '0xD5796ecd9903168d22BD0386c8494e1479e18eED',
        simple: '0x06f5A8a5086453efeE31B0299AD4044E63669340',
    },
    cfManagerFactory: {
        basic: '0x823991e528e1caa7C13369A2860a162479906C90',
        vesting: '0xB853E8B0DC7542391F095070A75af57e3F0427Be',
    },
    apxRegistry: {
        address: '0xd355adCdf57B39e7751A688158515CE862F14e23',
        owner: '0x083D85EA574E276E86841202B159D60f3473E671',
        assetManager: '0x083D85EA574E276E86841202B159D60f3473E671',
        priceManager: '0x083D85EA574E276E86841202B159D60f3473E671'
    },
    faucetService: {
        address: '0xAfd8f9ad1AB03f6EA49c67F50C406552b000fAd2',
        owner: '0x083D85EA574E276E86841202B159D60f3473E671',
        callers: ['0xc06fcee3870a8115F5d3284121Fff1E049a39Ca4'],
        reward: '200000000000000000',
        threshold: '200000000000000000'
    },
    nameRegistry: {
        address: '0xdFB1F288b9845d4afE879aF554d4D2f1fb8A531d',
        owner: '0x083D85EA574E276E86841202B159D60f3473E671'
    },
    feeManager: {
        address: '0x7c6912280D9c28e42c208bE79ccb2c8fC71Bd7EA',
        owner: '0x083D85EA574E276E86841202B159D60f3473E671',
        treasury: '0xC42676564481FB66E10b93545a9f41C81cc7813D'
    },
    walletApproverService: {
        address: '0xdD929a6D4B10Af9674dbdf7682EFAf1A48a90ABb',
        owner: '0x083D85EA574E276E86841202B159D60f3473E671',
        callers: ['0x0382Fe477878c8C3807aB427D0DB282EFfa01CD6'],
        reward: '200000000000000000'
    },
    investService: '0xba92ac2560e2f99d4dd10c5572dcaae9eeb9573c',
    payoutManager: '0x785e44E6bE12068216f513a460c490DAc9631aC5',
    merkleTreePathValidator: '0x743BFd8395b13157A3cE6b1D8c1aC172a20B4d4d',
    payoutService: '0x9982bb7bD0160B869D8E6Ca7559e53B01D2165eb',
    queryService: '0x05633b916e9ca43366f51fe7506126ceae0dc5d9',
    deployerService: '0xf47CF4f0E0cb0097d7C0955068bF98733586A87e',
    emptyFactory: '0xca07985612E7BD509C4a2BDc04e27D851cf50a92'
}

interface TokenizerConfig {
    issuerFactory: {
        basic: string,
    },
    assetFactory: {
        basic: string,
        transferable: string,
        simple: string,
    }
    cfManagerFactory: {
        basic: string,
        vesting: string,
    },
    apxRegistry: {
        address: string,
        owner: string,
        assetManager: string,
        priceManager: string
    },
    faucetService: {
        address: string,
        owner: string,
        callers: string[],
        reward: string
        threshold: string
    },
    nameRegistry: {
        address: string,
        owner: string
    },
    feeManager: {
        address: string,
        owner: string,
        treasury: string
    },
    walletApproverService: {
        address: string,
        owner: string,
        callers: string[],
        reward: string
    },
    investService: string,
    payoutManager: string,
    payoutService: string,
    merkleTreePathValidator: string,
    queryService: string,
    deployerService: string,
    emptyFactory: string
}
