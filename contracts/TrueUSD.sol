pragma solidity ^0.4.23;

import "./modularERC20/ModularPausableToken.sol";
import "openzeppelin-solidity/contracts/ownership/NoOwner.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./CanDelegate.sol";
import "./BurnableTokenWithBounds.sol";
import "./CompliantToken.sol";
import "./TokenWithFees.sol";
import "./StandardDelegate.sol";
import "./WithdrawalToken.sol";
import "./BurnQueue.sol";
import "./RefferalRewardSheet.sol";

// This is the top-level ERC20 contract, but most of the interesting functionality is
// inherited - see the documentation on the corresponding contracts.
contract TrueUSD is 
    ModularPausableToken, 
    HasNoTokens, 
    HasNoContracts, 
    BurnableTokenWithBounds, 
    CompliantToken, 
    TokenWithFees, 
    WithdrawalToken, 
    StandardDelegate, 
    CanDelegate
{

    using SafeMath for *;

    string public name = "Jinvest";
    string public symbol = "JIN";
    uint8 public constant decimals = 18;
    // Q: is not used
    uint8 public constant rounding = 2;

    // stores total euros invested
    uint256 public totalSupplyEuro;

    // Token price in ether (wei)
    uint256 public price = 10**uint256(decimals);

    // Token price in euro in 2 decimals
    uint8 public euroDecimal = 18;
    uint256 public euroPrice = 100 * 10**uint256(euroDecimal);


    event RefferalRewardSheetSet(address indexed sheet);
    RefferalRewardSheet refferalRewardSheet;


    BurnQueue public burnQueue;

    event ChangeTokenName(string newName, string newSymbol);
    event BurnQueueSet(address indexed queue);

    constructor() public {
        totalSupply_ = 0;
        burnMin = 10000 * 10**uint256(decimals);
        burnMax = 20000000 * 10**uint256(decimals);
    }

    function setBurnQueue(address _queue) public onlyOwner returns(bool) {
        burnQueue = BurnQueue(_queue);
        burnQueue.claimOwnership();
        emit BurnQueueSet(_queue);
        return true;
    }

    function changeTokenName(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        emit ChangeTokenName(_name, _symbol);
    }

    // disable most onlyOwner functions upon delegation, since the owner should
    // use the new version of the contract
    modifier onlyWhenNoDelegate() {
        require(address(delegate) == address(0),"a delegate contract exist");
        _;
    }

    function forceMint(address _to, uint256 _value) onlyWhenNoDelegate onlyOwner public returns (bool) {
        super.mint(_to, _value);
    }

    function mint(address _to, uint256 _value) onlyWhenNoDelegate internal returns (bool) {
        super.mint(_to, _value);
    }
    function setBalanceSheet(address _sheet) onlyWhenNoDelegate public returns (bool) {
        return super.setBalanceSheet(_sheet);
    }
    function setRefferalRewardSheet(address _sheet) onlyWhenNoDelegate public returns (bool) {
        refferalRewardSheet = RefferalRewardSheet(_sheet);
        refferalRewardSheet.claimOwnership();
        emit RefferalRewardSheetSet(_sheet);
        return true;
    }
    function setAllowanceSheet(address _sheet) onlyWhenNoDelegate public returns (bool) {
        return super.setAllowanceSheet(_sheet);
    }
    function setBurnBounds(uint256 _min, uint256 _max) onlyWhenNoDelegate public {
        super.setBurnBounds(_min, _max);
    }
    function setRegistry(Registry _registry) onlyWhenNoDelegate public {
        super.setRegistry(_registry);
    }
    function changeStaker(address _newStaker) onlyWhenNoDelegate public {
        super.changeStaker(_newStaker);
    }
    function wipeBlacklistedAccount(address _account) onlyWhenNoDelegate public {
        super.wipeBlacklistedAccount(_account);
    }
    function changeStakingFees(
        uint256 _transferFeeNumerator,
        uint256 _transferFeeDenominator,
        uint256 _mintFeeNumerator,
        uint256 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint256 _burnFeeNumerator,
        uint256 _burnFeeDenominator,
        uint256 _burnFeeFlat
    ) onlyWhenNoDelegate public {
        super.changeStakingFees(
            _transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat
        );
    }

    function burnAllArgs(address _burner, uint256 _value ,string _note) internal {
        uint256 currentPrice = price;
        uint256 currentEuroPrice = this.euroPrice();

        require(currentPrice > 0, "token has no price yet");

        uint256 burnAmount = _value;
        if (!registry.hasAttribute(_burner, NO_FEES)) {
            uint256 burnFee = super.checkBurnFee(_value);
            burnAmount = _value.sub(burnFee);
        }

        // Q: check burnAmount > 0 is cleaner
        require(burnAmount.mul(currentPrice).div(10**uint256(decimals)) > 0, "insufficient burn amount");
        burnQueue.push(_burner, burnAmount, currentPrice, currentEuroPrice);

        super.burnAllArgs(_burner, _value, _note);
    }

    function settleABurn() public onlyOwner {
        address reqBurner;
        uint256 reqValue;
        uint256 reqPrice;
        uint256 reqEuroPrice;
        uint256 reqTimestamp;
        (reqBurner, reqValue, reqPrice, reqEuroPrice, reqTimestamp) = burnQueue.pop();
        reqBurner.transfer(reqValue.mul(reqPrice).div(10**uint256(decimals)));

        // uint256 reqEuroValue = reqValue.mul(reqEuroPrice).div(10**uint256(euroDecimal));
        totalSupplyEuro = totalSupplyEuro.sub(reqEuroPrice);
    }

    function settleAllBurns() external onlyOwner {
        while (burnQueue.count() != 0) {
            settleABurn();
        }
    }

    function totalDebt() external onlyOwner view returns (uint256) {
        return burnQueue.totalDebt().div(10**uint256(decimals));
    }


    // Alternatives to the normal NoOwner functions in case this contract's owner
    // can't own ether or tokens.
    // Note that we *do* inherit reclaimContract from NoOwner: This contract
    // does have to own contracts, but it also has to be able to relinquish them.
    function reclaimEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(ERC20Basic token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(_to, balance);
    }

    // Q: price??? eth-euro or token-euro or token-eth
    function setTokenPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTokenEuroPrice(uint256 _price) external onlyOwner {
        euroPrice = _price;
    }

    function () external payable {
        require(msg.value > 0, "sent value should at least be 1 wei");

        // No minting if any fund sent from staker.
        // It's probably for burn request withdrawals.
        if (msg.sender == staker)
            return;

        uint256 currentPrice = this.price();
        require(currentPrice > 0, "token has no price yet");
        uint256 tokensInvest = msg.value.mul(10**uint256(decimals)).div(currentPrice);
        mint(msg.sender, tokensInvest);

        uint256 currentEuroPrice = this.euroPrice();
        uint256 eurosInvest = tokensInvest.mul(currentEuroPrice).div(10**uint256(euroDecimal));
        // update total invested euros
        totalSupplyEuro = totalSupplyEuro.add(eurosInvest);
        // update reward sheet 
        
    }

}
