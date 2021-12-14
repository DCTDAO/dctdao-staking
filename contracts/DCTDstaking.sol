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
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The CAKE TOKEN!
    IERC20 public syrup;
    IERC20 public rewardToken;

    // uint256 public maxStaking;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;
    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    //Total lpTokens staked
    uint256 public totalStaked = 0;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 _syrup,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        syrup = _syrup;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _syrup,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }
    
    function changeStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }
    
    function changeEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }
    
    function changeRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accCakePerShare = accCakePerShare + (cakeReward * 1e12) / lpSupply;
        }
        return (user.amount * accCakePerShare) / 1e12 - user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accCakePerShare = pool.accCakePerShare + (cakeReward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Stake SYRUP tokens to StakingPool
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        // require (_amount.add(user.amount) <= maxStaking, 'exceed max stake');

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accCakePerShare) / 1e12 - user.rewardDebt;
            if(pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            totalStaked = totalStaked + _amount;
        }
        user.rewardDebt = (user.amount * pool.accCakePerShare) /1e12;

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw SYRUP tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = (user.amount *pool.accCakePerShare) /1e12 - user.rewardDebt;
        if(pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.transfer(address(msg.sender), _amount);
            totalStaked = totalStaked - _amount;
        }
        user.rewardDebt = (user.amount * pool.accCakePerShare)/ 1e12;

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        totalStaked = totalStaked - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        uint256 totalBalance = rewardToken.balanceOf(address(this));
        uint256 availableRewards = totalBalance - totalStaked;
         
        require(_amount < availableRewards, 'not enough rewards');
        rewardToken.transfer(address(msg.sender), _amount);
    }
    
    function saveMe(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

}