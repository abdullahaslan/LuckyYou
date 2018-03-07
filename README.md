# LuckyYou
Ethereum Smart Contract for Campaings

This project is another learning opportunity on how to build smart contracts and understanding limitations on the Solidity programming language. Main idea is, awarding consumers under the campaign. Companys like Pepsi, Magnum makes campaign evert year and give some awards to consumers. We will store products products barcode number with hashing. If not barcode will be seen by people

There are three roles on this contract.

1. Company :Start a new campaign and decide product count. Also can change awardAmount(coin).

2. Consumers : After getting product consumers will enter the products barcode number to system. If exist they win some coin, may be ether.

3. Owner: Add, delete company. Change coin supply.

    event insertCompanyEvent(uint32 _companyId);
    
    event insertProductEvent(uint32 _companyId, uint32 _productId);
    
    event insertBarcodeEvent(address _companyAddress, uint32 _companyId, uint32 _productId, uint32 _barcodeNumber);
    
    event checkBarcodeEvent(address _checkerAddress, uint32 _companyId, uint32 _productId, uint32 _barcodeNumber);
    
    event userWonEvent(address _checkerAddress, uint32 _companyId, uint32 _productId, uint32 _barcodeNumber, uint32 _coinAmount);


Please provide comments and improvements as this project is a learning opportunity. 


Token files copied from [OpenZeppelin/zeppelin-solidity](https://github.com/OpenZeppelin/zeppelin-solidity)
