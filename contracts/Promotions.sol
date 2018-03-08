/**
 * @title Promotions
 * @dev The Promotions contract
 * @author Abdullah Aslan
 */
pragma solidity ^0.4.17;

import "./token/PromotionToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Promotions is Ownable {
    
    
    using SafeMath for uint;
    
    uint public tokensMinted = 0;
    uint public minimumSupply = 1; //minimum token amount to sale at one transaction
    uint insertBarcodeWei = 1*10**14;
    uint256 public constant MAXIMUM_SUPPLY = 2500000 * 10**18;       

    MintableToken token;
    
    event AddCompanyEvent();
     event LoadBalanace(uint256 _balance);
    event AddProductEvent(address _companyAddress, uint32 _productId);
    event AddBarcodeEvent(address _companyAddress,  uint32 _productId, uint32 _barcodeNumber);
    event CheckBarcodeEvent(address _checkerAddress,uint32 _productId, uint32 _barcodeNumber);
    event UserWonEvent(address _checkerAddress, uint32 _productId, uint32 _barcodeNumber, uint32 _coinAmount);
  
    enum Status { Registered, Payed, Stopped }
    
    enum AvaliableStatus { Active, Passive }
    
    struct barcode {
        bytes32 barcodeId; 
        uint256 timestamp; 
        uint32 rewardAmountInWei;
        AvaliableStatus status;
    }

    struct product {
        address companyAddress;
        uint32 productId;
        uint256 startDate;
        uint256 endDate;             
        uint32 promotionCount;       
        uint256 timestamp;
        AvaliableStatus status;
    }
    
    struct company{
        string companyName;
        uint32 balance;
        uint256 timestamp;
        string name;
        string email;
        Status status;
    }

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

    address LYAccount = 0x4558d71CA1eda15601767dbA2114Ed1c6d150Eb6;
    /// @notice the init function that is run automatically when contract is created
    function Promotions() {
        owner = msg.sender;
        token = new PromotionToken();
    }
    
    function getBalance(address _address) public returns (uint256) {        
        return token.balanceOf(_address);
    }
    
    function registerCompany(string _companyName, string _email) public 
    {
         if(companyMap[msg.sender].timestamp != 0)  revert();
         
        company memory newCompany;      
        newCompany.name = _companyName;
        newCompany.email = _email;
        newCompany.timestamp = block.timestamp;
        newCompany.status = Status.Registered;    
        
        companyMap[msg.sender] = newCompany; 
        companies.push(newCompany);        
    }
    
    
    function loadBalanceToCompany() public payable returns (uint256) {    
       
        if(companyMap[msg.sender].timestamp == 0)  revert();
        require(tokensMinted.add(msg.value) <= MAXIMUM_SUPPLY);
        if(msg.value < 1 ether) throw; // accept exactly 1 ether and nothing else
      
        LYAccount.transfer(msg.value);
        
        token.mint(msg.sender, msg.value);
        tokensMinted.add(msg.value);
        
        company storage cmp = companyMap[msg.sender];    
        cmp.status = Status.Payed;
        
        companyMap[msg.sender] = cmp; 
        companies.push(cmp);     
        
        return  token.balanceOf(msg.sender);
        
    }
    
    //company adds product
    function addProduct (uint32 _productId, uint32 _duration, uint32 _promotionCount) public returns (uint32) {                      
        if (productMap[_productId].productId == _productId) revert();                
        if (companyMap[msg.sender].timestamp == 0 ) revert();

        product memory newProduct;
        newProduct.productId = _productId;
        newProduct.startDate = now ;
        newProduct.endDate = now + _duration * 1 seconds;
        newProduct.promotionCount = _promotionCount;
        newProduct.timestamp = block.timestamp;
        newProduct.status = AvaliableStatus.Active;
        newProduct.companyAddress = msg.sender;       

        productMap[_productId] = newProduct;
        products.push(newProduct);

        return 1;
    }

    //company adds barcode
    function addBarcode(uint32 _productId, uint32 _barcodeNumber, uint32 _rewardAmount) payable returns(bool) {       
         //product not exist or product company != companyId
        if (productMap[_productId].productId == 0 || productMap[_productId].companyAddress != msg.sender) revert(); 
        //barcode exist
        if (barcodeMap[keccak256(_barcodeNumber)].barcodeId != 0) revert();   
        
        if(token.balanceOf(msg.sender) < insertBarcodeWei) revert();

        barcode memory newBarcode;
        newBarcode.barcodeId = keccak256(_barcodeNumber);
        newBarcode.timestamp = block.timestamp;
        newBarcode.rewardAmountInWei = _rewardAmount;
        newBarcode.status = AvaliableStatus.Active; // isUsed
        barcodeMap[newBarcode.barcodeId] = newBarcode;

        barcodes.push(newBarcode);        
        //bakiyesinde azaltma yap
        token.transferFrom(msg.sender, owner, insertBarcodeWei);

        return true;
    }

    function checkBarcode(uint32 _productId, uint32 _barcodeNumber)  public payable returns(uint32) {   
        //product exist  
        if (productMap[_productId].productId == 0) revert();
        //barcode exist
        if (barcodeMap[keccak256(_barcodeNumber)].rewardAmountInWei == 0) revert();        
        //campaing expired
        if(productMap[_productId].startDate > now || productMap[_productId].endDate < now ) revert();

        barcode storage luckyBarcode= barcodeMap[keccak256(_barcodeNumber)];
        if (luckyBarcode.status == AvaliableStatus.Active) {
            luckyBarcode.status = AvaliableStatus.Passive;
            barcodeMap[keccak256(_barcodeNumber)] = luckyBarcode;
            
            product storage productUpdate  = productMap[_productId];
            productUpdate.promotionCount = productUpdate.promotionCount-1;
            
            token.transferFrom(productUpdate.companyAddress, msg.sender, luckyBarcode.rewardAmountInWei);
            
            return 1;
        }        
        return 0;
      }
}
