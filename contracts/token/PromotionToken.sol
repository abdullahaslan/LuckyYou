pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract PromotionToken is MintableToken{
	string public constant name = "PromotionToken";
	string public constant symbol = "PROC";
	uint public constant decimals = 18;

	
	
}
