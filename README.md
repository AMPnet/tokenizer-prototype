# Tokenizer Contracts Prototype

AMPnet Crowdfunding Platform v1.0 written in Solidity language.

## Contract types

There are 4 different logical units provided in the contracts package:
- Issuer
- Asset (Token)
- Campaign
- Snapshot Distributor

## Issuer

Issuer represents an organization, company or a token issuance entity. This entity groups the Assets (tokens) created under this unit.
The Issuer defines two important properties:
- approved wallets map: holds the wallets allowed to take part in the campaigns
- stablecoin: the address of the token used for the payment method for all of the campaigns created under this issuer
- wallet approver: the address allowed to whitelist wallets and approve them for investing in the campaigns requiring this feature

## Asset

It's actually an ERC20 token with additional features implemnted on top of the standard implementation.
There are three different Asset types provided by the contracts package (named as in the list below):
- asset
    - can't be transferred
    - can be liquidated
    - can be mirrored
- asset-transferable
    - is transferable
    - can be liquidated
- asset-simple
    - pure ERC20 with no liquidations and mirroring

Liquidation: Once the token is created it can be sold on the multiple crowdfunding rounds with different prices. Token
can also start getting traded publicly. To liquidate the token means fo the token creator to buyback all of the tokens from
the market in a single transaction. To do this in a fair way, the price is taken from the market, and from the most expensive
funding round in the crowdunfindg history for this token. The liquidation price is then the larger of these two values.
Token creator must provide the funds necessary for the liquidation which is equal to the total supply minus his own holdings
multiplied by the liquidation price of the token. If this is fulfilled, the token owner can proceed with the liquidation,
provide the liquidation funds and buy the full supply of the tokens. Then liquidated holders can pull back their share of the
liquidation funds. This mechanism can be useful if the token created on-chain actually represents the real world asset or the
share in the existing company. In cases like these, usually the lien is put on the real world asset and the terms to unlock the lien
can be to be a 100% owner of the token defined in the lien documents. This way the real world asset was basically mapped
on-chain while also providing the guarantee that the legal system is protecting your ownership if you are the token holder.

Mirroring: Is only used in the asset package. Since the token here is not transferable, there exists the mechanism to unlock the
token for trading. To enable this feature, one must join the APX network as a verified asset and the network will provide
the means to mirror the token into it's transferable counterpart and use it for trading or transferring. This is useful
if you are using the most restricted type of the asset but would still like to be able to trade it. The instructions on how
to join the APX network will be published here soon.

How to choose an asset type? Depends on your legal model and the need for the restrictions on-chain if token represents the real
world asset (be it real estate, company equity, or similar). Asset is the restricted one, AssetTransferable is the middle ground
while the AssetSimple represents the basic token with no additional features.

## Campaign

To raise funds Asset Token holder can create the campaign through which the token can be sold at a defined terms and conditions.
The campaign can define the following:
    - is the wallet whitelisting required for the investors to participate
    - token price
    - minimum per wallet investment
    - maximum per wallet investment
    - soft cap required to be reached before the campaign can be closed by the creator
The accepted payment method for the investors is defined in the Issuer configuration under which the Asset and Campaign have been
created.

There are two different campaign types provided in the managers package:
- regular campaign
- campaign with vesting schedule

The campaign with vesting schedule adds one additional step to the campaign finalization procedure which is the vesting schedule definition. The campaign owner must provide the vesting schedule once the campaign is finalized in order to start unlocking the tokens linearly to the investors. Schedule is defined by the three parameters:
- start date (unix timestamp)
- cliff duration
- vesting duration

These three when combined can support for almost any of the required token unlocking schedules.

## Factories

Each of the 4 different contracts can and will be deployed by calling its factory contract's <i>create()</i> method. That way, we can have official factory contracts deployed on the chain at known addresses and we can be sure that all the contracts created this way weren't tampered with. Every factory holds addresses of all the instances ever created by calling their <i>create()</i> function. It's easy to check for the contract with address A if it was created by an official factory or not.

List of factory contracts:
- AssetFactory
- AssetSimpleFactory
- IssuerFactory
- CfManagerSoftcapFactory
- CfManagerSoftcapVestingFactory
- PayoutManagerFactory.sol

## Deployment addresses

The addresses of deployed contracts are stored and tracked in [deployments.ts](./deployments.ts)

## Local development with [Remix](https://remix-project.org/) (in browser)

1. Open a link between localhost and Remix:
```
npm run remix-dev
```
2. Open [Remix](https://remix.ethereum.org), go to *Workspaces*, select *-connect to localhost-*, and your local files will be in sync with your Remix workspace.
g
