# LuckyYou
Ethereum Smart Contract for Campaings

This project is another learning opportunity on how to build smart contracts and understanding limitations on the Solidity programming language. Main idea is, give award to consumers for a specific campaign. 

Used token is a sample of MintableToken. 

There are three roles on this contract.

1. Company :Register, LoadBalance (spend ether get coin) AddProduct and AddBarcode. 
     ```sh
     function registerCompany(string _companyName, string _email) public
     function loadBalanceToCompany() public payable returns (uint256)
     function addProduct (uint32 _productId, uint32 _duration, uint32 _promotionCount) public returns (uint32)
     function addBarcode(uint32 _productId, uint32 _barcodeNumber, uint32 _rewardAmount) payable returns(bool) 
     function finishCampaign(uint32 _productId) public
      ```

2. Consumers : After getting product consumers will enter the products barcode number to system. If exist they win some coin.
           ```sh
           function checkBarcode(uint32 _productId, uint32 _barcodeNumber)  public payable returns(uint32)
           ```
3. Owner: Change adding barcode fee. Get ether for giving coin to company.

    
Please provide comments and improvements as this project is a learning opportunity. 


Token files copied from [OpenZeppelin/zeppelin-solidity](https://github.com/OpenZeppelin/zeppelin-solidity)
