/**
 * @title Promotions
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
pragma solidity ^0.4.17;

import "./token/PromotionToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
/// @author Abdullah ASlan

contract Promotions is Ownable {

    using SafeMath for uint256;
    
    uint public tokensMinted = 0;
    uint public minimumSupply = 1; //minimum token amount to sale at one transaction
    uint public constant MAXIMUM_SUPPLY = 2500000 * 10**18;
    
    
    
    uint32 minimumReward = 1;
    uint32 maximumReward = 1000;
   
    uint insertProductWei = 100;

    MintableToken token;
    
    event InsertCompanyEvent();
    event InsertProductEvent(address _companyAddress, uint32 _productId);
    event InsertBarcodeEvent(address _companyAddress,  uint32 _productId, uint32 _barcodeNumber);
    event CheckBarcodeEvent(address _checkerAddress,uint32 _productId, uint32 _barcodeNumber);
    event UserWonEvent(address _checkerAddress, uint32 _productId, uint32 _barcodeNumber, uint32 _coinAmount);
  
    enum Status { Active, Passive }
    
    struct barcode {
        bytes32 barcodeId; 
        uint256 timestamp; 
        uint32 rewardAmountInWei;
        Status status;
    }

    struct product {
        address companyAddress;
        uint32 productId;
        uint256 startDate;
        uint256 endDate;             
        uint32 promotionCount;       
        uint256 timestamp;
        Status status;
    }
    
    struct company{
        string companyName;
        uint32 balance;
        uint256 timestamp;
        address companyAddress;
        Status status;
    }

    // represents a roll

   
    
    struct winner {
        address winnerAddress;
        uint256 timestamp;
        bytes32 barcodeId;
        uint32 productId;
        address companyAddress;
        uint32 reward;
        
    }


    barcode[] barcodes; 
    product[] products;
    winner[] winners;
    company[] companies;
    
    mapping(uint32 => product) public productMap;
    mapping(bytes32 => barcode) public barcodeMap;
    mapping(address => winner) public winnerMap;
    mapping(address => company) public companyMap;
    
    address public owner;    // address of the token being used for this    


    /// @notice the init function that is run automatically when contract is created

    function Promotions() {
        owner = msg.sender;
        token = new PromotionToken();
    }
    
    function getBalance(address _address) public onlyOwner returns (uint256) {
        
        return token.balanceOf(_address);
    }

    function setMinimumReward(uint32 _minimumReward) public onlyOwner {
        minimumReward = _minimumReward;
    }

    function setMaximumReward(uint32 _maximumReward) public onlyOwner {
        maximumReward = _maximumReward;
    }

    function setBalanceToCompany(address _companyAddress, uint256 _balance) payable onlyOwner{
        
        token.mint(_companyAddress,_balance);
        tokensMinted.add(_balance);
    }
    
    function insertCompany(address _companyAddress, uint256 _balance) public onlyOwner returns (uint256) {
    
        if(companyMap[_companyAddress].companyAddress != address(0))  revert();
        require(tokensMinted.add(_balance) <= MAXIMUM_SUPPLY);
        
        company memory newCompany;    
        newCompany.companyAddress = _companyAddress;    
        newCompany.timestamp = block.timestamp;
        newCompany.status = Status.Active;    
        companyMap[_companyAddress] = newCompany; 

        companies.push(newCompany);
        
        setBalanceToCompany(_companyAddress,_balance);
        
        return  token.balanceOf(_companyAddress);
        
    }
    
    //company adds product
    function insertProduct(uint32 _productId, uint32 _duration, uint32 _promotionCount) public returns (uint32) {      
                
        if (productMap[_productId].productId == _productId) revert();        
        
        if (companyMap[msg.sender].companyAddress != msg.sender ) revert();

        product memory newProduct;
        newProduct.productId = _productId;
        newProduct.startDate = now ;
        newProduct.endDate = now + _duration * 1 seconds;
        newProduct.promotionCount = _promotionCount;
        newProduct.timestamp = block.timestamp;
        newProduct.status = Status.Active;
        newProduct.companyAddress = msg.sender;       

        productMap[_productId] = newProduct;
        products.push(newProduct);

        return 1;
    }

    //company adds barcode
    function insertBarcode(uint32 _productId, uint32 _barcodeNumber, uint32 _rewardAmount) payable returns(bool) {
       
         //product not exist or product company != companyId
        if (productMap[_productId].productId == 0 || productMap[_productId].companyAddress != msg.sender) revert();          
         //if barcode exist 
         
         
         barcode storage barcodex = barcodeMap[keccak256(_barcodeNumber)];
        if (barcodeMap[keccak256(_barcodeNumber)].barcodeId != 0) revert(); 
        
        if(_rewardAmount < minimumReward || _rewardAmount > maximumReward) revert();
        

        barcode memory newBarcode;
        newBarcode.barcodeId = keccak256(_barcodeNumber);
        newBarcode.timestamp = block.timestamp;
        newBarcode.rewardAmountInWei = _rewardAmount;
        newBarcode.status = Status.Active; // isUsed

        barcodeMap[newBarcode.barcodeId] = newBarcode;

        barcodes.push(newBarcode);
        
        //bakiyesinde azaltma yap
        token.transferFrom(msg.sender, owner, insertProductWei);

        return true;
    }

    function checkBarcode(uint32 _productId, uint32 _barcodeNumber)  public payable returns(uint32) {
        

        if (productMap[_productId].productId == 0) revert();

        if (barcodeMap[keccak256(_barcodeNumber)].rewardAmountInWei == 0) revert();
        
        //campaing expired
        if(productMap[_productId].startDate > now || productMap[_productId].endDate < now ) revert();

        barcode  storage barcode2= barcodeMap[keccak256(_barcodeNumber)];

        if (barcode2.status == Status.Active) {

            barcode2.status = Status.Passive;
            barcodeMap[keccak256(_barcodeNumber)] = barcode2;
            
            product storage product2  = productMap[_productId];
            product2.promotionCount = product2.promotionCount-1;
            //selfdestruct(users[i]);
            
            token.transferFrom(product2.companyAddress, msg.sender, barcode2.rewardAmountInWei);
            
            return 1;
        }
        
        return 0;

      }
}
