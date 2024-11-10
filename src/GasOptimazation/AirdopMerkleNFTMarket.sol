// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "src/NFTMarket/NFTMarket.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract AirdopMerkleNFTMarket is NFTMarket,Multicall {
    bytes32 public merkleRoot;

    constructor()  {
    }

    function setMerkelRoot(bytes32 merkleRoot_) external {
        require(msg.sender == owner, "Only owner can set merkle root");
        merkleRoot = merkleRoot_;
    }

    function permitPrePay(
        address tokenAddr,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        IERC20Permit(tokenAddr).permit(owner, spender, value, deadline, v, r, s);
    }

    // 50% discount if buyer in whitelist
    // check white list and change price
    function claimNFT(address wantedNftAddr, uint tokenId, bytes32[] calldata proof) public {
        bool isInWhileList = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        if (isInWhileList) {
            //50% discount
            require(goods[wantedNftAddr][tokenId].isListing);
            goods[wantedNftAddr][tokenId].price = (goods[wantedNftAddr][tokenId].price * 1e10 / 2) / 1e10;
        }

        buyNFT(msg.sender, wantedNftAddr,  tokenId);
    }

}