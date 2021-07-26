#!/bin/bash

############################################ Network selection ############################################
# One of the networks defined in the hardhat.config.ts. The script will be executed on the selected network.
# > If running local node, value should be: localhost
# > If need to use hardhat in-memory chain kept alive only while the process is running, value should be: hardhat
export NETWORK=mumbai

############################################## Faucet params ##############################################
# > stablecoin is an address of the stablecoin deployed and owned by the accounts[0]
# > stablecoin and receiver are mandatory params
# > amount will default to 100k if left empty
export STABLECOIN=
export RECEIVER=
export AMOUNT=

############################################### Run script ###############################################
STABLECOIN=${STABLECOIN}
RECEIVER=${RECEIVER}
AMOUNT=${AMOUNT}
hh run scripts/faucet.ts --network $NETWORK
