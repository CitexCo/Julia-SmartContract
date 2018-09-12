pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract BurnQueue is Claimable {
    using SafeMath for uint256;

    struct BurnRequest {
        address from;
        uint256 value;
        uint256 price;
        uint256 euroPrice;
        uint256 timestamp;
    }

    uint256 private backPos = 0;
    uint256 private frontPos = 0;
    BurnRequest[] public burnRequests;

    event RequestBurn(address indexed from, uint256 value, uint256 price, uint256 euroPrice, uint256 timestamp);

    function push(address _from, uint256 _value, uint256 _price, uint256 _euroPrice) public onlyOwner {
        BurnRequest memory req = BurnRequest(_from, _value, _price, _euroPrice, block.timestamp);
        emit RequestBurn(_from, _value, _price, _euroPrice, block.timestamp);

        backPos = burnRequests.length;
        burnRequests.push(req);
    }

    function pop() public onlyOwner returns (address, uint256, uint256, uint256, uint256) {
        require(burnRequests.length > 0);
        BurnRequest memory req = burnRequests[frontPos];
        delete burnRequests[frontPos];
        frontPos++;
        if (frontPos > backPos) {
            backPos = 0;
            frontPos = 0;
            burnRequests.length = 0;
        }
        return (req.from, req.value, req.price, req.euroPrice, req.timestamp);
    }

    function count() public onlyOwner view returns (uint256) {
        if (burnRequests.length == 0)
            return 0;
        return backPos - frontPos + 1;
    }

    function totalDebt() public onlyOwner view returns (uint256) {
        
        if (count() == 0)
            return 0;

        uint256 debt = 0;
        for (uint256 index=frontPos; index<=backPos; index++) {
            BurnRequest memory req = burnRequests[index];
            debt += req.value.mul(req.price);
        }
        return debt;
    }
}
