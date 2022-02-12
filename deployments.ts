export const Mumbai: TokenizerConfig = {
    apxRegistry: '0x93148Bd574232Acae13B12d6A3a1843109f5243b',
    issuerFactory: {
        basic: '0x463d65eba0efa397ad5d7Fa49f335DC44F124d03',
    },
    assetFactory: {
        basic: '0x45f036A8FD250F00E7732A1516Ba7342B1A66915',
        transferable: '0x2a977180D3694F952fA240734B171f7c241Db37f',
        simple: '0x9d94eBdCd676B25EdABbaadf343140bf1Bf60e36',
    },
    cfManagerFactory: {
        basic: '0x5b14f62551FA82B8AeD78A72c8C483DAD5727C86',
        vesting: '0xe1284684E0f30089b114DFC141Ada9843c155f3f',
    },
    faucetService: '0x8085c74Ac04cd630b050a3a5822fa8C5c5ED2CE1',
    deployerService: '0xEE5ac09500968b1b11AFEbfd9af64e50a734db37',
    nameRegistry: '0x5771E32E4aC5Db8b06DfAD4774E2a5358cc90FF5',
    feeManager: '0xC74f47030aedEBa155a65921E62e8B3C0Bf77140',
    queryService: '0xf05E598F841709e980c9F3eF4D8818b161E18D32',
    walletApproverService: '0x9D320608c28ecB79daE1c9E778A75040eC7F7d79',
    investService: '0x6da35932606866801762cBEC8698BD684d9D1699',
}

export const Matic: TokenizerConfig = {
    apxRegistry: '0xd355adCdf57B39e7751A688158515CE862F14e23',
    issuerFactory: {
        basic: '0x9DFC2e793a3e88ae61766aaC24F7167501953dC9',
    },
    assetFactory: {
        basic: '0x7530569e6669a06110f62E2ab39E3B0653Bd885E',
        transferable: '0x0d7E2e171C63f913901467D980C357c9D8ACbeb6',
        simple: '0x06f5A8a5086453efeE31B0299AD4044E63669340',
    },
    cfManagerFactory: {
        basic: '0x823991e528e1caa7C13369A2860a162479906C90',
        vesting: '0xB853E8B0DC7542391F095070A75af57e3F0427Be',
    },
    faucetService: '0x7945504432ea431EAa529Cf083e714543A643526',
    deployerService: '0x1D736776bF08726753fb8d5960d34F3e179af133',
    nameRegistry: '0xeB186b3C94e66e0f1CFe525D9187fb6933e8c91A',
    feeManager: '0x7c6912280D9c28e42c208bE79ccb2c8fC71Bd7EA',
    queryService: '0x4A37374Ae69aC637be890539bb8D851518c08e74',
    walletApproverService: '0xeD249D3b3cfe53f0FA655f8814Baff404AA0B27c',
    investService: '0xa1C7cAF622cfc35C53c786A9564F71b58CAE477a',
}

interface TokenizerConfig {
    apxRegistry: string,
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
    faucetService: string,
    deployerService: string,
    nameRegistry: string,
    feeManager: string,
    queryService: string,
    walletApproverService: string,
    investService: string,
}
