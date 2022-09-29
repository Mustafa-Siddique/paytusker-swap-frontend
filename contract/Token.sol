/**
 **
 **    Total tax - 6%
 **
 **    2% - Marketing: this will be sent straight to the tax generated marketing wallet as Paytusker Token.
 **    2% - dev: this will be sent to a dev wallet as Paytusker Token
 **    2% - buyback
 **
 **/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d/contracts/utils/Context.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d/contracts/access/Ownable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d/contracts/utils/Address.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d/contracts/utils/math/SafeMath.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d/contracts/interfaces/IERC20.sol';

/**
 * @title TokenStorage
 */
abstract contract TokenStorage {
  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  mapping(address => uint256) internal _rOwned;
  mapping(address => uint256) internal _tOwned;
  mapping(address => mapping(address => uint256)) internal _allowances;
  mapping(address => bool) internal _blackList;

  /// @dev A record of each accounts delegate
  mapping(address => address) internal _delegates;

  mapping(address => bool) internal _isExcludedFromFee;

  mapping(address => bool) internal _isExcluded;

  mapping(address => uint256) internal _txTimeLimit;

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  using Address for address;
  address[] internal _excluded;
  address public _devWallet;
  address public _marketingWallet;
  bool internal pause = false;
  uint256 internal constant MAX = ~uint256(0);
  uint256 internal _tTotal = 1000000 * 10**18;
  uint256 internal _rTotal = (MAX - (MAX % _tTotal));
  uint256 internal _tFeeTotal;

  string internal _name = 'Paytusker Token';
  string internal _symbol = 'PTT';
  uint8 internal _decimals = 18;

  // 6% Fees Distribution
  uint256 public _taxFee = 2; // Buyback or Reflection
  uint256 internal _previousTaxFee = _taxFee;

  uint256 public _devFee = 2;
  uint256 internal _previousDevFee = _devFee;

  uint256 public _marketingFee = 2;
  uint256 internal _previousMarketingFee = _marketingFee;
  // END - 10% Fees Distribution
  uint256 public _maxTxAmount = 25000 * 10**18;
}

library Events {
  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}

contract Token is Context, IERC20, Ownable, TokenStorage {
  using SafeMath for uint256;

  constructor(address payable marketingWallet, address payable devWallet) {
    _rOwned[_msgSender()] = _rTotal;

    _devWallet = devWallet;
    _marketingWallet = marketingWallet;
    //exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_devWallet] = true;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), 'BEP20: mint to the zero address');

    _tTotal = _tTotal.add(amount);
    _rOwned[account] = _rOwned[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegator The address to get delegatee for
   */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
    require(blockNumber < block.number, 'CAKE::getPriorVotes: not yet determined');

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
    _delegates[delegator] = delegatee;

    emit Events.DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, 'CAKE::_writeCheckpoint: block number exceeds 32 bits');

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit Events.DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address _to, uint256 _amount) public onlyOwner {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
    );
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], 'Excluded addresses cannot call this function');
    //(uint256 rAmount,,,,,,,,) = _getValues(tAmount);
    uint256[8] memory values = _getValues(tAmount);
    uint256 rAmount = values[0];

    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
    require(tAmount <= _tTotal, 'Amount must be less than supply');
    uint256[8] memory values = _getValues(tAmount);
    if (!deductTransferFee) {
      return values[0]; // rAmount
    } else {
      return values[1]; //rTransferAmount;
    }
  }

  function checkTxTimeLimit(address _sender) private returns (bool) {
    if (_txTimeLimit[_sender] == 0) {
      _txTimeLimit[_sender] = block.timestamp;
      return true;
    } else if (block.timestamp > (_txTimeLimit[_sender] + 5 * 60)) {
      _txTimeLimit[_sender] = block.timestamp;
      return true;
    } else {
      return false;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function IsBlacklisted(address account) public view returns (bool) {
    return _blackList[account];
  }

  function excludeFromReward(address account) public onlyOwner {
    require(!_isExcluded[account], 'Account is already excluded');
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function blackListAccount(address account, bool _value) public onlyOwner {
    _blackList[account] = _value;
  }

  function includeInReward(address account) external onlyOwner {
    require(_isExcluded[account], 'Account is already excluded');
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    //(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tdev) = _getValues(tAmount);
    uint256[8] memory values = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(values[0]);
    _tOwned[recipient] = _tOwned[recipient].add(values[3]);
    _rOwned[recipient] = _rOwned[recipient].add(values[1]);
    _reflectFee(values[2], values[4]);
    _takeLiquidity(values[5]);
    _takeMarketing(values[6]);
    _takedev(values[7]);
    emit Transfer(sender, recipient, values[3]);
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function setMarketWallet(address _wallet) public onlyOwner {
    _marketingWallet = _wallet;
  }

  function setDevWallet(address _wallet) public onlyOwner {
    _devWallet = _wallet;
  }

  function togglePaused(bool _value) public onlyOwner {
    pause = _value;
  }

  function getIsPaused() public view returns (bool) {
    return pause;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setTaxFeePercent(uint256 taxFee) external onlyOwner {
    _taxFee = taxFee;
  }

  //to recieve ETH when swaping
  receive() external payable {}

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount) private view returns (uint256[8] memory values) {
    // (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tdev) = _getTValues(tAmount);
    uint256[5] memory tValues = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tValues, _getRate());
    // @return rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing, tdev
    return [rAmount, rTransferAmount, rFee, tValues[0], tValues[1], tValues[2], tValues[3], tValues[4]];
  }

  function _getTValues(uint256 tAmount) private view returns (uint256[5] memory tValues) {
    uint256 tFee = calculateTaxFee(tAmount); // token for distribution
    uint256 tLiquidity = 0; // liquidity pool amount
    uint256 tMarketing = calculateMarketingFee(tAmount); // marketing token to collect
    uint256 tdev = calculatedevFee(tAmount);
    uint256 tempTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
    uint256 tTransferAmount = tempTransferAmount.sub(tMarketing).sub(tdev);
    return [tTransferAmount, tFee, tLiquidity, tMarketing, tdev];
  }

  function _getRValues(uint256[5] memory tValues, uint256 currentRate)
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    //function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, tMarketing, tdev uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tValues[0].mul(currentRate);
    uint256 rFee = tValues[1].mul(currentRate);
    uint256 rLiquidity = tValues[2].mul(currentRate);
    uint256 rMarketing = tValues[3].mul(currentRate);
    uint256 rdev = tValues[4].mul(currentRate);
    uint256 tempTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
    uint256 rTransferAmount = tempTransferAmount.sub(rMarketing).sub(rdev);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function _takeMarketing(uint256 tMarketing) private {
    if (tMarketing == 0) return;
    _transfer(_msgSender(), _marketingWallet, tMarketing);
  }

  function _takedev(uint256 tdev) private {
    if (tdev == 0) return;
    _transfer(_msgSender(), _devWallet, tdev);
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(10**2);
  }

  function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_marketingFee).div(10**2);
  }

  function calculatedevFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_devFee).div(10**2);
  }

  function removeAllFee() private {
    if (_taxFee == 0 && _marketingFee == 0 && _devFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousMarketingFee = _marketingFee;
    _previousDevFee = _devFee;

    _taxFee = 0;
    _marketingFee = 0;
    _devFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;

    _marketingFee = _previousMarketingFee;
    _devFee = _previousDevFee;
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(!pause, "Token: Token transfers are paushed you can't perform the operations");
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');
    require(amount <= _maxTxAmount, 'Transfer amount exceeds the maxTxAmount.');
    require(checkTxTimeLimit(from), 'In TxTimeLimit please try after some time (5 min)');
    require(!_blackList[from], 'This account is blacklisted from the operations');

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    uint256 contractTokenBalance = balanceOf(address(this));
    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    //transfer amount, it will take tax, marketing, dev fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    if (!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) restoreAllFee();
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    //(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tdev) = _getValues(tAmount);
    uint256[8] memory values = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(values[0]);
    _rOwned[recipient] = _rOwned[recipient].add(values[1]);
    _reflectFee(values[2], values[4]);
    _takeLiquidity(values[5]);
    _takeMarketing(values[6]);
    _takedev(values[7]);
    emit Transfer(sender, recipient, values[3]);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tdev) = _getValues(tAmount);
    uint256[8] memory values = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(values[0]);
    _tOwned[recipient] = _tOwned[recipient].add(values[3]);
    _rOwned[recipient] = _rOwned[recipient].add(values[1]);
    _reflectFee(values[2], values[4]);
    _takeLiquidity(values[5]);
    _takeMarketing(values[6]);
    _takedev(values[7]);
    emit Transfer(sender, recipient, values[3]);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tdev) = _getValues(tAmount);
    uint256[8] memory values = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(values[0]);
    _rOwned[recipient] = _rOwned[recipient].add(values[1]);
    _reflectFee(values[2], values[4]);
    _takeLiquidity(values[5]);
    _takeMarketing(values[6]);
    _takedev(values[7]);
    emit Transfer(sender, recipient, values[3]);
  }
}
