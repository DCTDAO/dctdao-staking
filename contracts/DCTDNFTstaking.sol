//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
0. staker can stake only after lockingStarts
1. staker has to stake before stakingStarts
2. Staker can withdraw any time
2. a) If he withdraw and keeps still minimal amount in staking pool, he can still win
3. If he withdraw under the minimal staking pos, than he loses automatically

*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DCTDNFTstaking is Ownable {

    mapping(uint256 => mapping (address => uint256)) public stakes;

    struct PoolInfo {
        string name;
        address tokenAddress;
        uint256 lockingStarts;
        uint256 stakingStarts;
        uint256 stakingEnds;
        uint256 stakedTotal;
        uint256 stakedBalance;
        uint256 minimalAmount;
    }

    PoolInfo[] public poolInfo;
    uint256  public poolCount = 0;

    event Staked(uint256 indexed poolId, address indexed staker_, uint256 stakedAmount_, uint256 time);
    event Withdraw(uint256 indexed poolId, address indexed staker_, uint256 withdrawAmount, uint256 time);
    event PoolCreated(uint256 indexed poolId); 

     constructor () {}


    function createStakingPool(string memory name_,
        address tokenAddress_,
        uint256 lockingStarts_,
        uint256 stakingStarts_,
        uint256 stakingEnds_,
        uint256 minimalAmount_) onlyOwner public
        {
            require(minimalAmount_ > 0,"DCTDstaking: amountToStake has to be positive.");

            require(tokenAddress_ != address(0), "DCTDstaking: 0 address");


            require(stakingStarts_ > lockingStarts_, "DCTDstaking: staking starts must be after locking starts.");

            require(stakingEnds_ > stakingStarts_, "DCTDstaking: staking end must be after staking starts");
            poolCount++;
            poolInfo.push(
                PoolInfo({
                    name: name_,
                    tokenAddress: tokenAddress_,
                    lockingStarts: lockingStarts_,
                    stakingStarts: stakingStarts_,
                    stakingEnds: stakingEnds_,
                    stakedTotal: 0,
                    stakedBalance: 0,
                    minimalAmount: minimalAmount_
                })
            );

            emit PoolCreated(poolCount);
        }



    function _stake(uint256 poolId, uint256 amount)
    private
    _positive(amount)
    _realAddress(msg.sender)
    {
        address staker = msg.sender;
        PoolInfo storage pool = poolInfo[poolId];

        //_after(lockingStarts)
        require(block.timestamp > pool.lockingStarts, "DCTDstaking: bad timing, locking has not started."); 
        //before(stakingStarts)
        require(block.timestamp < pool.stakingStarts, "DCTDstaking: bad timing, staking has already started."); 

        //_hasAllowance(msg.sender, amount)
        uint256 ourAllowance = ERC20(pool.tokenAddress).allowance(staker, address(this));
        require(amount <= ourAllowance, "DCTDstaking: Make sure to add enough allowance");
        
        //Stacking requirements
        require(stakes[poolId][staker] == 0, "DCTDstaking: you are already staking.");
        require(amount >= pool.minimalAmount, "DCTDstaking: you have to stake at least minimal amount.");
        ERC20(pool.tokenAddress).transferFrom(staker, address(this), amount);
        emit Staked(poolId, staker, amount, block.timestamp);

        // Transfer is completed
        pool.stakedBalance = pool.stakedBalance + amount;
        pool.stakedTotal = pool.stakedTotal + amount;
        stakes[poolId][staker] = stakes[poolId][staker] + amount;
    }

    function withdraw(uint256 poolId, uint256 amount)
    public
    _positive(amount)
    _realAddress(msg.sender)
    {
        address sender = msg.sender;
        PoolInfo storage pool = poolInfo[poolId];
        require(amount <= stakes[poolId][sender], "DCTDstaking: not enough balance");
        stakes[poolId][sender] = stakes[poolId][sender] - amount;
        pool.stakedBalance = pool.stakedBalance - amount;
        ERC20(pool.tokenAddress).transfer(sender, amount);
        emit Withdraw(poolId, sender, amount, block.timestamp);
    }




    modifier _realAddress(address addr) {
        require(addr != address(0), "DCTDstaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "DCTDstaking: negative amount");
        _;
    }
}