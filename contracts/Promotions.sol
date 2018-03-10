/**
 * @title Promotions
 * @dev The Promotions contract
 * @author Abdullah Aslan
 */
pragma solidity ^0.4.17;

import "./token/PromotionToken.sol";
import "./zeppelin/MintableToken.sol";
import "./zeppelin/Ownable.sol";


contract Promotions is Ownable {    
    
    using SafeMath for uint;
    
    uint public tokensMinted = 0;
    uint public minimumSupply = 1; //minimum token amount to sale at one transaction
    uint insertBarcodeWei = 1*10**14;
    uint256 public constant MAXIMUM_SUPPLY = 2500000 * 10**18;       

    MintableToken token;
    
    event AddProductEvent(address _companyAddress, uint32 _productId);
    event UserWonEvent(address _checkerAddress, uint32 _productId, uint32 _barcodeNumber, uint32 _coinAmount);
  
    enum Status { Registered, Payed, Stopped }
    
    enum AvaliableStatus { Active, Passive, Started, Found }
    
    struct barcode {
        bytes32 barcodeId; 
        uint32 rewardAmountInWei;
        AvaliableStatus status;
        address winner;
    }

    struct product {
        address companyAddress;
        uint32 productId;           
        uint32 promotionCount;
        AvaliableStatus status;
    }
    
    struct company {
        string companyName;
        uint32 balance;
        Status status;
    }

    barcode[] barcodes; 
    product[] products;
    company[] companies;
    
    mapping(uint32 => product) public productMap;
    mapping(bytes32 => barcode) public barcodeMap;
    mapping(address => company) public companyMap;
    
    address public owner;    // address of the token being used for this   

    address public lyAccount = 0x4558d71CA1eda15601767dbA2114Ed1c6d150Eb6;
    
    /// @notice the init function that is run automatically when contract is created
    function Promotions() {
        owner = msg.sender;
        token = new PromotionToken();
    }

    function finishCampaign(uint32 _productId) public
    {        
        if (productMap[_productId].companyAddress != msg.sender) revert();
        if (productMap[_productId].productId == _productId) revert(); 

        product storage productUpdate  = productMap[_productId];
        productUpdate.status = AvaliableStatus.Passive;
        productMap[_productId] = productUpdate;
    }   

    function registerCompany() public 
    {
        if (companyMap[msg.sender].balance != 0)  revert();
         
        company memory newCompany;      
        newCompany.status = Status.Registered;    
        
        companyMap[msg.sender] = newCompany; 
        companies.push(newCompany);        
    }    
    
    function loadBalanceToCompany() public payable returns (uint256) {    
       
        if (companyMap[msg.sender].balance == 0)  revert();
        if (msg.value < 1 ether) revert(); // accept exactly 1 ether and nothing else
        require(tokensMinted.add(msg.value) <= MAXIMUM_SUPPLY); 
        
        company storage cmp = companyMap[msg.sender];    
        cmp.status = Status.Payed;
        
        companyMap[msg.sender] = cmp; 
        companies.push(cmp);     

        token.mint(msg.sender, msg.value);
        tokensMinted.add(msg.value);
        lyAccount.transfer(msg.value);  
        
        return  token.balanceOf(msg.sender);
        
    }
    
    //company adds product
    function addProduct (uint32 _productId,  uint32 _promotionCount) 
    public returns (uint32) {                      
        if (productMap[_productId].productId == _productId) revert();                
        if (companyMap[msg.sender].balance == 0) revert();

        product memory newProduct;
        newProduct.productId = _productId;
        newProduct.promotionCount = _promotionCount;
        newProduct.status = AvaliableStatus.Active;
        newProduct.companyAddress = msg.sender;       

        productMap[_productId] = newProduct;
        products.push(newProduct);
        emit AddProductEvent(msg.sender, _productId);
        return 1;
    }

    //company adds barcode
    function addBarcode(uint32 _productId, uint32 _barcodeNumber, uint32 _rewardAmount) 
    public payable returns(bool) {       
         //product not exist or product company != companyId
        if (productMap[_productId].productId == 0 || productMap[_productId].companyAddress != msg.sender) revert(); 
        //barcode exist
        if (barcodeMap[keccak256(_barcodeNumber)].barcodeId != 0) revert();   
        
        if (token.balanceOf(msg.sender) < insertBarcodeWei) revert();

        barcode memory newBarcode;
        newBarcode.barcodeId = keccak256(_barcodeNumber);
        newBarcode.rewardAmountInWei = _rewardAmount;
        newBarcode.status = AvaliableStatus.Started; // isUsed
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
        if (productMap[_productId].status == AvaliableStatus.Passive) revert();

        if (productMap[_productId].promotionCount == 0) revert();

        barcode storage luckyBarcode = barcodeMap[keccak256(_barcodeNumber)];
        if (luckyBarcode.status == AvaliableStatus.Started) {
            luckyBarcode.status = AvaliableStatus.Found;
            luckyBarcode.winner = msg.sender;
            barcodeMap[keccak256(_barcodeNumber)] = luckyBarcode;
            
            product storage productUpdate  = productMap[_productId];
            productUpdate.promotionCount = productUpdate.promotionCount-1;
            
            token.transferFrom(productUpdate.companyAddress, msg.sender, luckyBarcode.rewardAmountInWei);            
            emit UserWonEvent(msg.sender, _productId, _barcodeNumber, luckyBarcode.rewardAmountInWei);
            return 1;
        }        
        return 0;
    }
}