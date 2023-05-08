pragma solidity 0.7.5;

import 'https://github.com/OmniDexFinance/helper/blob/master/%40openzeppelin/contracts/utils/Pausable.sol';
import 'https://github.com/OmniDexFinance/helper/blob/master/%40openzeppelin/contracts/access/Ownable.sol';
import 'https://github.com/OmniDexFinance/helper/blob/master/%40openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import 'https://github.com/OmniDexFinance/helper/blob/master/%40openzeppelin/contracts/math/SafeMath.sol';
import 'https://github.com/OmniDexFinance/helper/blob/master/%40openzeppelin/contracts/token/ERC20/IERC20.sol';

contract OmnidexIncentivesVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable token; // incentive token
    address public admin;
    address public approvedSpender;
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);
    event Pause();
    event Unpause();

    /**
     * @notice Constructor
     * @param _token: Incentives token contract
     * @param _approvedSpender: PullRewardsIncentivesController contract
     * @param _admin: address of the admin
     * @param _dailyLimit: max permitted incentives spend each day
     */
    constructor(
        IERC20 _token,
        address _approvedSpender,
        address _admin,
        uint _dailyLimit
    ) public {
        token = _token;
        approvedSpender = _approvedSpender;
        admin = _admin;
        dailyLimit = _dailyLimit;

        // Infinite approve
        IERC20(_token).safeApprove(address(_approvedSpender), uint256(-1));
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin permitted");
        _;
    }

    /**
     * @notice Checks if the msg.sender is authorised to spend
     */
    modifier onlyAuth() {
        require(msg.sender == approvedSpender, "Not an authorised spender");
        _;
    }

    /**
     * @notice Deposits funds into the  Vault
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in TLOS)
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Nothing to deposit");
        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    function getIncentivesBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Withdraws all funds back to owner
     */
    function withdrawAll() external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Sets new daily limit
     * @dev Only callable by the contract owner.
     */
    function setDailyLimit(uint _newDailyLimit) external onlyOwner {
        require(_newDailyLimit >=0 , "Cannot be negative number");
        dailyLimit = _newDailyLimit;
    }

    function getDailyLimit() public view returns (uint) {
        return dailyLimit;
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    /**
     * @notice Withdraw unexpected tokens sent to the Charm Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(token), "Token cannot be same as incentives token");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Withdraws incentives from funds in the Vault
     * @notice can only be called by authorised spenders
     * @param _amount: amount to withdraw
     */
    function withdraw(address _to, uint256 _amount) public whenNotPaused onlyAuth {
        require(_amount > 0, "Nothing to withdraw");
        require(token.balanceOf(address(this)) > _amount, "Insufficient incentives available");
        if (isUnderLimit(_amount)){
            spentToday += _amount;
            token.safeTransfer(_to, _amount);
        }

        emit Withdraw(_to, _amount);
    }

     /*
     * Internal functions
     */
    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        return true;
    }
}