import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MyInscription} from "./Inscription.sol";
contract MyInscriptionFactory{

    constructor() {
        
    }

    function deployInscription(string symbol, uint totalSupply, uint perMint) public  {
        MyInscription inscription = new MyInscription(symbol, totalSupply, perMint);
    }
}