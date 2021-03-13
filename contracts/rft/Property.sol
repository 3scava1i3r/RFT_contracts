pragma solidity >=0.6.0 <0.8.0;

import './RFT.sol';
import '../@openzeppelin/contracts/math/SafeMath.sol';

contract Property is RFT {

    using SafeMath for uint256;

    /* struct P {
        string name;
        string symbol;
        uint256 decimals;
        uint256 id;
        address tokenOwner;
        uint256 fungibleTokenSupply;

    } */

    /* P[] public properties;  */

    address public admin;
    constructor () public {
        admin = msg.sender;
    }

    function _create(string memory _name , string memory _symbol , uint _decimals , uint256 _fungibleTokenSupply) public {
        require(msg.sender == admin , 'admin has the power to make new RFT');
        

        mint(_name , _symbol, _decimals , msg.sender ,_fungibleTokenSupply);
    }

    function _createRFTfromNFT(string memory _name , string memory _symbol , uint _decimals , uint256 _fungibleTokenSupply , uint256 _tokenid) public {
        require(msg.sender == admin , 'admin has the power to make new RFT');
        

        _createFT(_name , _symbol, _decimals , admin, _fungibleTokenSupply , _tokenid);
    }


    function _balanceFT(uint256 _id) view {
        require(msg.sender == admin , "admin has the power to see their balance(Fungible Token)");
    
        ftHolderBalance(_id , admin);

    }

    function _burn(uint256 _id) public{
        require(msg.sender == admin , "admin has the power to burn their token");

        burn( admin , _id);
    }


    /* function buyShare() external{
        


    } */

    /* function _transfer() {}
 */
}
