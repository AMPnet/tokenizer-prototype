#!/bin/bash

################################################## Guide ##################################################
# > Set 0x0000000000000000000000000000000000000000 for contract address field to skip deployment 

############################################ Network selection ############################################
# One of the networks defined in the hardhat.config.ts. The script will be executed on the selected network.
# > If running local node, value should be: localhost
# > If need to use hardhat in-memory chain kept alive only while the process is running, value should be: hardhat
export NETWORK=hardhat

########################################## Predeployed contracts ##########################################
# Factory and stablecoin addresses. These should be deployed upfront on prod version.
# > If omitted, new instance will be deployed for each of the missing fields.
export STABLECOIN=
export ISSUER_FACTORY=
export ISSUER_FACTORY_OLD=0x0000000000000000000000000000000000000000
export ASSET_FACTORY=
export ASSET_FACTORY_OLD=0x0000000000000000000000000000000000000000
export ASSET_TRANSFERABLE_FACTORY=
export ASSET_TRANSFERABLE_FACTORY_OLD=0x0000000000000000000000000000000000000000
export ASSET_SIMPLE_FACTORY=
export ASSET_SIMPLE_FACTORY_OLD=0x0000000000000000000000000000000000000000
export CF_MANAGER_FACTORY=
export CF_MANAGER_FACTORY_OLD=0x0000000000000000000000000000000000000000
export CF_MANAGER_VESTING_FACTORY=
export CF_MANAGER_VESTING_FACTORY_OLD=0x0000000000000000000000000000000000000000
export WALLET_APPROVER=
export WALLET_APPROVER_MASTER_OWNER=                # provide this param if WALLET_APPROVER field empty
export WALLET_APPROVER_ADDRESSES=
export APX_REGISTRY=  
export APX_REGISTRY_MASTER_OWNER=                   # provide this param if APX_REGISTRY field empty
export APX_REGISTRY_ASSET_MANAGER=                  # provide this param if APX_REGISTRY field empty
export APX_REGISTRY_PRICE_MANAGER=                  # provide this param if APX_REGISTRY field empty
export CAMPAIGN_FEE_MANAGER=
export CAMPAIGN_FEE_MANAGER_OWNER=                  # provide this param if CAMPAIGN_FEE_MANAGER field empty
export CAMPAIGN_FEE_MANAGER_TREASURY=               # provide this param if CAMPAIGN_FEE_MANAGER field empty
export REVENUE_FEE_MANAGER=
export REVENUE_FEE_MANAGER_OWNER=                   # provide this param if REVENUE_FEE_MANAGER field empty
export REVENUE_FEE_MANAGER_TREASURY=                # provide this param if REVENUE_FEE_MANAGER field empty
export PAYOUT_MANAGER=
export NAME_REGISTRY=
export NAME_REGISTRY_OWNER=                         # provide this param if NAME_REGISTRY field empty
export NAME_REGISTRY_OLD=                           # provide this param if NAME_REGISTRY field empty and old exists
export DEPLOYER_SERVICE=
export QUERY_SERVICE=
export FAUCET_SERVICE=
export FAUCET_SERVICE_MASTER_OWNER=                     # provide this param if FAUCET_SERVICE field empty
export FAUCET_SERVICE_ALLOWED_CALLERS=                  # provide this param if FAUCET_SERVICE field empty
export FAUCET_SERVICE_REWARD_PER_APPROVE=               # provide this param if FAUCET_SERVICE field empty (value is ETH, decimals are allowed)
export FAUCET_SERVICE_BALANCE_THRESHOLD_FOR_REWARD=     # provide this param if FAUCET_SERVICE field empty (value is ETH, decimals are allowed)
export INVEST_SERVICE=
export PAYOUT_SERVICE=
export MERKLE_TREE_PATH_VALIDATOR=

######################################## Mirrored token definition ########################################
# > Load existing MirroredToken at given address
export MIRRORED_TOKEN=0x0000000000000000000000000000000000000000
# > Or create a new one with the following properties
export MIRRORED_TOKEN_NAME=                         # provide this param if MIRRORED_TOKEN field empty
export MIRRORED_TOKEN_SYMBOL=                       # provide this param if MIRRORED_TOKEN field empty
export MIRRORED_TOKEN_ORIGINAL=                     # provide this param if MIRRORED_TOKEN field empty

############################################### Run script ###############################################
STABLECOIN=${STABLECOIN}
ISSUER_FACTORY=${ISSUER_FACTORY}
ISSUER_FACTORY_OLD=${ISSUER_FACTORY_OLD}
ASSET_FACTORY=${ASSET_FACTORY}
ASSET_FACTORY_OLD=${ASSET_FACTORY_OLD}
ASSET_TRANSFERABLE_FACTORY=${ASSET_TRANSFERABLE_FACTORY}
ASSET_TRANSFERABLE_FACTORY_OLD=${ASSET_TRANSFERABLE_FACTORY_OLD}
ASSET_SIMPLE_FACTORY=${ASSET_SIMPLE_FACTORY}
ASSET_SIMPLE_FACTORY_OLD=${ASSET_SIMPLE_FACTORY_OLD}
CF_MANAGER_FACTORY=${CF_MANAGER_FACTORY}
CF_MANAGER_FACTORY_OLD=${CF_MANAGER_FACTORY_OLD}
CF_MANAGER_VESTING_FACTORY=${CF_MANAGER_VESTING_FACTORY}
CF_MANAGER_VESTING_FACTORY_OLD=${CF_MANAGER_VESTING_FACTORY_OLD}
WALLET_APPROVER=${WALLET_APPROVER}
WALLET_APPROVER_MASTER_OWNER=${WALLET_APPROVER_MASTER_OWNER}
WALLET_APPROVER_ADDRESSES=${WALLET_APPROVER_ADDRESSES}
APX_REGISTRY=${APX_REGISTRY}
APX_REGISTRY_MASTER_OWNER=${APX_REGISTRY_MASTER_OWNER}
APX_REGISTRY_ASSET_MANAGER=${APX_REGISTRY_ASSET_MANAGER}
APX_REGISTRY_PRICE_MANAGER=${APX_REGISTRY_PRICE_MANAGER}
CAMPAIGN_FEE_MANAGER=${CAMPAIGN_FEE_MANAGER}
CAMPAIGN_FEE_MANAGER_OWNER=${CAMPAIGN_FEE_MANAGER_OWNER}
CAMPAIGN_FEE_MANAGER_TREASURY=${CAMPAIGN_FEE_MANAGER_TREASURY}
REVENUE_FEE_MANAGER=${REVENUE_FEE_MANAGER}
REVENUE_FEE_MANAGER_OWNER=${REVENUE_FEE_MANAGER_OWNER}
REVENUE_FEE_MANAGER_TREASURY=${REVENUE_FEE_MANAGER_TREASURY}
PAYOUT_MANAGER=${PAYOUT_MANAGER}
NAME_REGISTRY_OWNER=${NAME_REGISTRY_OWNER}
NAME_REGISTRY=${NAME_REGISTRY}
NAME_REGISTRY_OLD=${NAME_REGISTRY_OLD}
DEPLOYER_SERVICE=${DEPLOYER_SERVICE}
QUERY_SERVICE=${QUERY_SERVICE}
FAUCET_SERVICE=${FAUCET_SERVICE}
FAUCET_SERVICE_MASTER_OWNER=${FAUCET_SERVICE_MASTER_OWNER}
FAUCET_SERVICE_ALLOWED_CALLERS=${FAUCET_SERVICE_ALLOWED_CALLERS}
FAUCET_SERVICE_REWARD_PER_APPROVE=${FAUCET_SERVICE_REWARD_PER_APPROVE}
FAUCET_SERVICE_BALANCE_THRESHOLD_FOR_REWARD=${FAUCET_SERVICE_BALANCE_THRESHOLD_FOR_REWARD}
INVEST_SERVICE=${INVEST_SERVICE}
PAYOUT_SERVICE=${PAYOUT_SERVICE}
MERKLE_TREE_PATH_VALIDATOR=${MERKLE_TREE_PATH_VALIDATOR}
MIRRORED_TOKEN=${MIRRORED_TOKEN}
MIRRORED_TOKEN_NAME=${MIRRORED_TOKEN_NAME}
MIRRORED_TOKEN_SYMBOL=${MIRRORED_TOKEN_SYMBOL}
MIRRORED_TOKEN_ORIGINAL=${MIRRORED_TOKEN_ORIGINAL}
hh run scripts/deploy-test-env.ts --network $NETWORK
