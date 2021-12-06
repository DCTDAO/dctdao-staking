//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




contract StakingPool is Ownable {
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        address rewardToken; // reward token for users
        uint256 rewardPerBlock; //tokens created per block.
        uint256 startBlock;  // The block number when CAKE mining starts.
        uint256 endBlock;  // The block number when CAKE mining ends.
        uint256 totalStaked; //Total lpTokens staked
        uint256 lastRewardBlock;
    }

    uint256  public poolCount = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;



    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 stackingToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        //syrup = _syrup;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // staking pool
        poolInfo = PoolInfo({
            lpToken: stackingToken,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        });
    }

    function createStackingPool(

    ) public onlyOwner {
        poolCount++;
    }

    function stopReward(uint256 poolId) public onlyOwner {
        PoolInfo storage pool = poolInfo[poolId];
        poolInfo[poolId].endBlock = block.number;
    }
    
    function changeStartBlock(uint256 poolId, uint256 _startBlock) public onlyOwner {
        PoolInfo storage pool = poolInfo[poolId];
        pool[poolId].startBlock = _startBlock;
    }
    
    function changeEndBlock(uint256 poolId, uint256 _endBlock) public onlyOwner {
        PoolInfo storage pool = poolInfo[poolId];
        pool[poolId].endBlock = _endBlock;
    }
    
    function changeRewardPerBlock(uint256 poolId, uint256 _rewardPerBlock) public onlyOwner {
        PoolInfo storage pool = poolInfo[poolId];
        pool[poolId].rewardPerBlock = _rewardPerBlock;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 poolId, uint256 _from, uint256 _to) public view returns (uint256) {
         PoolInfo storage pool = poolInfo[poolId];
        if (_to <= pool[poolId].bonusEndBlock) {
            return _to - _from;
        } else if (_from >= pool[poolId].bonusEndBlock) {
            return 0;
        } else {
            return pool[poolId].bonusEndBlock - _from;
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(uint256 poolId, address _user) external view returns (uint256) { 
        UserInfo storage user = userInfo[_user];
        uint256 accCakePerShare = poolInfo.accCakePerShare;
        uint256 lpSupply = totalStaked;
        if (block.number > poolInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
            uint256 cakeReward = (multiplier * rewardPerBlock * poolInfo.allocPoint) / totalAllocPoint;
            accCakePerShare = accCakePerShare + cakeReward * 1e12 / lpSupply;
        }
        return user.amount * accCakePerShare / 1e12  - user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 poolId) public { 
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStaked;
        if (lpSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier * rewardPerBlock * poolInfo.allocPoint / totalAllocPoint;
        poolInfo.accCakePerShare = poolInfo.accCakePerShare + cakeReward * 1e12 / lpSupply;
        poolInfo.lastRewardBlock = block.number;
    }


    // Stake SYRUP tokens to StakingPool
    function stake(uint256 poolId, uint256 _amount) public { 
        UserInfo storage user = userInfo[msg.sender];

        // require (_amount.add(user.amount) <= maxStaking, 'exceed max stake');

        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount * poolInfo.accCakePerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
            }
        }
        if(_amount > 0) {
            poolInfo.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            totalStaked = totalStaked + _amount;
        }
        user.rewardDebt = user.amount * poolInfo.accCakePerShare / 1e12;

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw SYRUP tokens from STAKING.
    function withdraw(uint256 poolId, uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount * poolInfo.accCakePerShare / 1e12 - user.rewardDebt;
        if(pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            poolInfo.lpToken.transfer(address(msg.sender), _amount);
            totalStaked = totalStaked - _amount;
        }
        user.rewardDebt = user.amount * poolInfo.accCakePerShare / 1e12;

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        poolInfo.lpToken.transfer(address(msg.sender), user.amount);
        totalStaked = totalStaked - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        uint256 totalBalance = rewardToken.balanceOf(address(this));
        uint256 availableRewards = totalBalance - totalStaked;
         
        require(_amount < availableRewards, "not enough rewards");
        rewardToken.transfer(address(msg.sender), _amount);
    }
    
    function saveMe(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

}