pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Claimable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @dev The contract provides storage of refferals and their rewards states.
 */
contract RefferalRewardSheet is Claimable {
    using SafeMath for uint256;

    event SetRefferal(address _user, address _ref, string _note);
    event RewardAdded(address _ref, uint256 _reward, string _note);
    event RewardReceived(address _ref, uint256 _reward, string _note);

    uint256 public totalRewards;
    uint256 public totalDeposits;
    uint256 public totalDebts;

    struct RewardBalance {
        uint256 totalRewards;
        uint256 totalDeposits;
    }

    // relates a ueser to its referrer
    mapping (address => address) refferalMap;
    // relates a referrer to its balance
    mapping (address => RewardBalance) refferalRewards;

    /**
     * @dev Sets the refferal address associated with _user.
     * @param _user User address its refferal should be set
     * @param _ref  The address should be set as refferal of _user
     */
    function setRefferal(address _user, address _ref) public onlyOwner {
        require(_user != address(0), 'Invalid User Address.');
        require(_ref != address(0), 'Invalid Refferal Address.');
        refferalMap[_user] = _ref;
        emit SetRefferal(_user, _ref, 'Refferal Table Updated.');
    }
    
    /**
     * @dev Unsets the refferal address associated with _user.
     * @param _user User address its refferal should be dropped
     */
    function unsetRefferal(address _user) public onlyOwner {
        require(_user != address(0), 'Invalid User Address.');
        refferalMap[_user] = address(0);
        emit SetRefferal(_user, address(0), 'Refferal Table Updated.');
    }

    /**
     * @dev Adds value a refferal's total rewards.
     * @param _ref The address of refferal.
     * @param _value User's invest value.
     */
    function addReward(address _ref, uint256 _value) public onlyOwner {
        require(_ref != address(0), 'Invalid Refferal Address');
        RewardBalance storage rewardBalance = refferalRewards[_ref];
        rewardBalance.totalRewards = rewardBalance.totalRewards.add(_value);
        totalRewards = totalRewards.add(_value);
        totalDebts = totalDebts.add(_value);
        emit RewardAdded(_ref, _value, 'Refferal Reward Added');
    }

    /**
     * @dev Adds _value to total deposits of refferal _ref.
     * @param _ref Address of the refferal claims its rewards.
     * @param _value The value of which the user claims as its rewards.
     */
    function addDeposit(address _ref, uint256 _value) public onlyOwner {
        require(_ref != address(0), 'Invalid Refferal Address');
        RewardBalance storage rewardBalance = refferalRewards[_ref];
        require(rewardBalance.totalRewards >= rewardBalance.totalDeposits.add(_value), 'Credit is too low.');
        rewardBalance.totalDeposits = rewardBalance.totalDeposits.add(_value);
        totalDeposits = totalDeposits.add(_value);
        totalDebts = totalDebts.sub(_value);
        emit RewardReceived(_ref, _value, 'Refferal Reward Received');
    }

    /**
     * @dev Returns total rewards of refferal _ref.
     * @param _ref The address of refferal its total rewards should be returned.
     * @return a uint256 as total rewards of refferal _ref.
     */
    function rewardsOf(address _ref) public view returns (uint256) {
        require(_ref != address(0), 'Invalid Refferal Address');
        RewardBalance memory refBalance = refferalRewards[_ref];
        return refBalance.totalRewards;
    }

    /**
     * @dev Returns total remaining credits of refferal _ref.
     * @param _ref The address of refferal its total credits should be returned.
     * @return a uint256 as total credits remained for refferal _ref.
     */
    function creditOf(address _ref) public view returns (uint256) {
        require(_ref != address(0), 'Invalid Refferal Address');
        RewardBalance memory refBalance = refferalRewards[_ref];
        if (refBalance.totalRewards < refBalance.totalDeposits) return 0;
        else return refBalance.totalRewards.sub(refBalance.totalDeposits);
    }

    /**
     * @dev Returns the refferal address of given _user address.
     * @param _user Specified user address whose refferal should be returned.
     * @return an address associated with the refferal of given _user.
     */
    function refferalOf(address _user) public view returns (address) {
        require(_user != address(0), 'Invalid User Address');
        return refferalMap[_user];
    }

}
