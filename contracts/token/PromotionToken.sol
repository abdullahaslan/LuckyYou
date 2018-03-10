pragma solidity ^0.4.17;

import "../zeppelin/MintableToken.sol";


contract PromotionToken is MintableToken {
	string public constant name = "PromotionToken";
	string public constant symbol = "PROC";
	uint public constant decimals = 18;

}
