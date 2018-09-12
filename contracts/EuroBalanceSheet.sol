pragma solidity "0.4.23";

import "openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// A wrapper around the balanceOf mapping.
contract EuroBalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => uint256) public euroBalanceOf;

    function addBalanceEuro(address _addr, uint256 _value) public onlyOwner {
        euroBalanceOf[_addr] = euroBalanceOf[_addr].add(_value);
    }

    function subBalanceEuro(address _addr, uint256 _value) public onlyOwner {
        euroBalanceOf[_addr] = euroBalanceOf[_addr].sub(_value);
    }

    function setBalanceEuro(address _addr, uint256 _value) public onlyOwner {
        euroBalanceOf[_addr] = _value;
    }
}
