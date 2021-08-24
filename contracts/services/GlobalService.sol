// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GlobalService {

    //------------------------
    //  STATE
    //------------------------
    address masterOwner;
    address walletApprover;
    mapping (address => bool) public owners;
    mapping (address => bool) public approvedWallets;
    mapping (address => uint256) public maxDeploymentsPerFactory;
    mapping (address => mapping (address => uint256)) public deploymentsCount;
    
    //------------------------
    //  EVENTS
    //------------------------
    

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        address _masterOwner,
        address _walletApprover,
        address[] memory ownersList,
        address[] memory approvedWalletsList
    ) {
        masterOwner = _masterOwner;

        for (uint256 i = 0; i < ownersList.length; i++) { owners[ownersList[i]] = true; }
        for (uint256 i = 0; i < approvedWalletsList.length; i++) { approvedWallets[approvedWalletsList[i]] = true; }
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(msg.sender == masterOwner || owners[msg.sender], "GlobalService: only owner can call this function");
        _;
    }

    modifier masterOwnerOnly() {
        require(msg.sender == masterOwner, "GlobalService: only master owner can call this function");
        _;
    }

    //------------------------
    //  IGlobalService IMPL
    //------------------------
    function registerDeployment(address creator) external {
        deploymentsCount[msg.sender][creator] += 1;
    }

}
