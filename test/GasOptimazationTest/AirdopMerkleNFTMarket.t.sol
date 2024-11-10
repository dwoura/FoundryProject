// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {AirdopMerkleNFTMarket} from "src/GasOptimazation/AirdopMerkleNFTMarket.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/MerkleTree.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract AirdopMerkleNFTMarketTest is Test {
    MyPermitToken erc20;
    MyERC721 erc721;
    AirdopMerkleNFTMarket market;

    uint256 private developerPrivateKey;
    address public developer;
    uint256 private alicePrivateKey;
    address public alice; // nft buyer

    // merkle rel
    // generated from https://github.com/dwoura/UpchainStudy/tree/main/21_Gas_Optimization/merkleTreeWhiteList/src/index.ts
    uint256 public buyerPK =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // anvil first test account
    address public buyer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 public root =
        bytes32(
            0xd4453790033a2bd762f526409b7f358023773723d9e9bc42487e4996869162b6
        );
    bytes32[] public proof = [
        bytes32(
            0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0
        ),
        bytes32(
            0x7e0eefeb2d8740528b8f598997a219669f0842302d3c573e9bb7262be3387e63
        )
    ];
    bytes[] public calls;

    function setUp() public {
        // setup account
        alicePrivateKey = uint256(keccak256("alice private key"));
        alice = vm.addr(alicePrivateKey);
        developerPrivateKey = uint256(keccak256("developer private key"));
        developer = vm.addr(developerPrivateKey);

        // setup contract
        vm.startPrank(developer);
        erc20 = new MyPermitToken(developer);
        market = new AirdopMerkleNFTMarket();
        erc721 = new MyERC721();
        vm.stopPrank();

        // setup merkle tree from index.ts
        vm.prank(developer);
        market.setMerkelRoot(root);

        //console.log("bbbbb",token.balanceOf(alice));
    }

    function test_ClaimNFT() public {
        uint256 tokenId = erc721.mint(alice, "uri");

        //==== alice list
        vm.prank(alice);
        erc721.approve(address(market), tokenId);
        vm.prank(alice);
        market.list(address(erc721), tokenId, address(erc20), 1 ether); // price 1 ether

        //==== buyer buy
        deal(address(erc20), buyer, 1 ether);
        bytes32 digest = MessageHashUtils.toTypedDataHash(
            erc20.DOMAIN_SEPARATOR(),
            keccak256(
                abi.encode(
                    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                    buyer,
                    address(market),
                    1 ether,
                    erc20.nonces(buyer),
                    block.timestamp + 60 * 60 * 24
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPK, digest);

        calls.push(
            abi.encodeWithSelector(
                AirdopMerkleNFTMarket.permitPrePay.selector,
                address(erc20),
                buyer,
                address(market),
                1 ether,
                block.timestamp + 60 * 60 * 24,
                v,
                r,
                s
            )
        );
        calls.push(
            abi.encodeWithSelector(
                AirdopMerkleNFTMarket.claimNFT.selector,
                address(erc721),
                tokenId,
                proof
            )
        );
        vm.prank(buyer);
        market.multicall(calls); // market inherit from multicall

        uint256 wlPrice = (1 ether * 1e10 / 2) / 1e10;
        assertEq(erc20.balanceOf(alice), wlPrice);
        assertEq(erc721.ownerOf(tokenId), buyer);

    }
}
