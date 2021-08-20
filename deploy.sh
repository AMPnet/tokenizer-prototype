#!/bin/bash

################################################## Guide ##################################################
# > Set 0x0000000000000000000000000000000000000000 for contract address field to skip deployment 

############################################ Network selection ############################################
# One of the networks defined in the hardhat.config.ts. The script will be executed on the selected network.
# > If running local node, value should be: localhost
# > If need to use hardhat in-memory chain kept alive only while the process is running, value should be: hardhat
export NETWORK=mumbai

########################################## Predeployed contracts ##########################################
# Factory and stablecoin addresses. These should be deployed upfront on prod version.
# > If omitted, new instance will be deployed for each of the missing fields.
export STABLECOIN=0x0000000000000000000000000000000000000000
export ISSUER_FACTORY=0x0000000000000000000000000000000000000000
export ASSET_FACTORY=0x0000000000000000000000000000000000000000
export CF_MANAGER_FACTORY=0x0000000000000000000000000000000000000000
export WALLET_APPROVER=
export WALLET_APPROVER_MASTER_OWNER=0xe0bE763bE9b91042Cbd38aB68Ed04BD8E1F1C2e9                        # provide this param if WALLET_APPROVER field empty
export DEPLOYER=0x0000000000000000000000000000000000000000
export QUERY_SERVICE=0x0000000000000000000000000000000000000000

############################################ Issuer definition ############################################
# > Load existing Issuer at given address
export ISSUER=0x0000000000000000000000000000000000000000
# > Or create a new one with the following properties
export ISSUER_ANS_NAME=                                     # defaults to "test-issuer"
export ISSUER_OWNER=                                        # defaults to deployerAddress (accounts[0])
export ISSUER_IPFS=                                         # defaults to "issuer-info-ipfs-hash"

############################################ Asset definition ############################################
# > Load existing Asset at given address
export ASSET=0x0000000000000000000000000000000000000000
# > Or create a new one with the following properties
export ASSET_NAME=                                          # defaults to "Test Asset"
export ASSET_ANS_NAME=                                      # defaults to "test-asset"
export ASSET_SYMBOL=                                        # defaults to "$TSTA"
export ASSET_IPFS=                                          # defaults to "asset-info-ipfs-hash"
export ASSET_SUPPLY=                                        # defaults to 1M tokens
export ASSET_OWNER=                                         # defaults to $ISSUER_OWNER value
export ASSET_TRANSFER_WHITELIST_REQUIRED=                   # defaults to false

########################################### Campaign definition ###########################################
# > Load existing Campaign at given address
export CAMPAIGN=0x0000000000000000000000000000000000000000
# > Or create a new one with the following properties
export CAMPAIGN_OWNER=                                      # defaults to $ISSUER_OWNER
export CAMPAIGN_ANS_NAME=                                   # defaults to "test-campaign"
export CAMPAIGN_TOKEN_PRICE=                                # defaults to $1
export CAMPAIGN_SOFT_CAP=                                   # defaults to $100k
export CAMPAIGN_MIN_INVESTMENT=                             # defaults to $1
export CAMPAIGN_MAX_INVESTMENT=                             # defaults to $100k
export CAMPAIGN_INVESTOR_WHITELIST_REQUIRED=                # defaults to false
export CAMPAIGN_IPFS=                                       # defaults to "test-campaign-ipfs-hash"

############################################### Run script ###############################################
STABLECOIN=${STABLECOIN}
ISSUER_FACTORY=${ISSUER_FACTORY}
ASSET_FACTORY=${ASSET_FACTORY}
CF_MANAGER_FACTORY=${CF_MANAGER_FACTORY}
ISSUER=${ISSUER}
ISSUER_OWNER=${ISSUER_OWNER}
ISSUER_WALLET_APPROVER=${ISSUER_WALLET_APPROVER}
ISSUER_IPFS=${ISSUER_IPFS}
ASSET=${ASSET}
ASSET_NAME=${ASSET_NAME}
ASSET_SYMBOL=${ASSET_SYMBOL}
ASSET_IPFS=${ASSET_IPFS}
ASSET_SUPPLY=${ASSET_SUPPLY}
ASSET_OWNER=${ASSET_OWNER}
ASSET_TRANSFER_WHITELIST_REQUIRED=${ASSET_TRANSFER_WHITELIST_REQUIRED}
CAMPAIGN=${CAMPAIGN}
CAMPAIGN_OWNER=${CAMPAIGN_OWNER}
CAMPAIGN_TOKEN_PRICE=${CAMPAIGN_TOKEN_PRICE}
CAMPAIGN_SOFT_CAP=${CAMPAIGN_SOFT_CAP}
CAMPAIGN_INVESTOR_WHITELIST_REQUIRED=${CAMPAIGN_INVESTOR_WHITELIST_REQUIRED}
CAMPAIGN_IPFS=${CAMPAIGN_IPFS}
hh run scripts/deploy-test-env.ts --network $NETWORK
