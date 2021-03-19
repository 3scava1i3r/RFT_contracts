pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


import './RFT.sol';
import 'https://github.com/3scava1i3r/RFT_contracts/blob/main/contracts/NEW_RFT/openzeppelin-solidity/contracts/math/SafeMath.sol';



contract R is RFT  {
    
    using SafeMath for uint256;
    
    uint256 public currentId;
    uint256 public tradecounter;
    
    event TradeStatusChange(uint256 _id, bytes32 status);

    constructor(
        string memory _RFTName,
        string memory _symbol
        
        ) RFT(_RFTName ,_symbol ) public {
        
             
        }
        
        mapping (uint256 => Trade) public trades;
        
        struct Trade {
            address seller;
            uint256 RFTId;   // RFT's token ID
            uint256 Price;
            bytes32 status;  // Open, Executed, Cancelled
        
        }
        
        /**
         * @dev Function to create a new RFT 
         */
         
        function create(string memory name,string memory symbol , uint256 fungibleTokenSupply ,string memory URI) public returns(bool) {
            mint(name,symbol,18,msg.sender,fungibleTokenSupply);
            _setTokenURI(currentId , URI);
            
            transferFrom(msg.sender , address(this) , currentId);
            
            currentId++;
            
        }
        
        /**
         * @dev Function to create a new RFT based trade by a seller
         */
         
         function openTradeWithNewRFT(string memory name,string memory symbol , uint256 fungibleTokenSupply, string memory _URI, uint256 RFTprice ) public  {
             
             mint(name,symbol,18,msg.sender,fungibleTokenSupply);
            _setTokenURI(currentId, _URI);
            
            transferFrom(msg.sender , address(this) , currentId);
            
            trades[tradecounter] = Trade({
                seller:msg.sender,
                RFTId: currentId,
                Price: RFTprice,
                status :"Open"
            });
            
            emit TradeStatusChange(tradecounter , "Open");
            currentId++;
            tradecounter++;
        
         }
         
         
         /**
         *  @dev Function to cancel a RFT based trade
         */
         
         function canceltrade(uint256 id) public {
             
             
             Trade storage trade = trades[id];
             require(msg.sender == trade.seller , "Trade can be cancelled only by seller.");
             require(trade.status == "Open" , "Trade status is Open");
             safeTransferFrom(address(this) , trade.seller, trade.RFTId );
             
             trades[id].status = "Cancelled";
             emit TradeStatusChange(id , "Cancelled");
         }
         
         
         
         function getTrade(uint256 id) public view returns (Trade memory trade_) {
                Trade memory trade = trades[id];
                return trade;
                
            }
        
    
    
        
}