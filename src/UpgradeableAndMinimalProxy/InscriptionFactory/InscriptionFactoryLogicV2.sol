// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Inscription} from "./Inscription.sol";
import {Test, console} from "forge-std/Test.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IInscriptionFactoryLogic} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/IInscriptionFactoryLogic.sol";
contract InscriptionFactoryLogicV2 is IInscriptionFactoryLogic{
    address[] public inscriptionAddresses;
    address public inscriptionTemplate; //set a deployed InscriptionV2 addr
    uint256 public mintFee;
    bool public isV2Initialized;
    constructor() {
    }

    modifier OnlyInitialized{
        require(isV2Initialized == true, "V2 should be initialized");
        _;
    }

    function initialize(address inscriptionTemplate_,uint256 mintFee_) public {
        require(msg.sender == getProxyAdmin(),"only proxyAdmin can do this");
        isV2Initialized = true;
        inscriptionTemplate = inscriptionTemplate_;
        mintFee = mintFee_;
    }
 
    function getOwner() public returns(address){
        ProxyAdmin proxyAdmin = ProxyAdmin(getProxyAdmin());
        return proxyAdmin.owner();
    }

    function getProxyAdmin() public returns(address){
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSignature("proxyAdmin()"));
        require(success, "failed to call proxyAdmin");
        (address proxyAdminAddr) = abi.decode(data,(address));
        return proxyAdminAddr;
    }

    function deployInscription(string memory symbol, uint256 totalSupply, uint256 perMint) public OnlyInitialized{
        require(inscriptionTemplate!=address(0),"inscriptionTemplate could not be address 0");
        // 最小代理部署
        address inscriptionAddress = Clones.clone(inscriptionTemplate); // ????

        // // 获取管理员地址
        // // 合约内 call 合约中另一个函数，msgsender 不会改变，依然是外部调用者，因为上下文没变。
        // (bool success, bytes memory data) = address(this).call(abi.encodeWithSignature("proxyAdmin()"));

        // require(success, "failed to call proxyAdmin");
        // (address proxyAdminAddr) = abi.decode(data,(address));

        // // 从管理员合约地址获取管理员地址
        // ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddr);
        // address adminAddr = proxyAdmin.owner();

        Inscription(inscriptionAddress).initialize(symbol, totalSupply, perMint,address(this));

        inscriptionAddresses.push(inscriptionAddress);
    }
    
    function mintInscription(address tokenAddr) public payable override OnlyInitialized{
        // pay fee
        require(msg.value == mintFee, "mint fee not enough");
        Inscription token = Inscription(tokenAddr);
        token.mint(msg.sender);

        // transfer fee
        (bool success,) = getOwner().call{value: address(this).balance}("");
        require(success, "failed to transfer eth");
    }

    function getDeployedAddress(uint256 id) view external returns(address){
        return inscriptionAddresses[id];
    }
}