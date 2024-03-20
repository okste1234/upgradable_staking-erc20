// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;
import "./interfaces/IERC20.sol";

contract RCXToken is IERC20 {
    string public tokenName;
    string public symbol;
    uint public decimal;
    uint private _totalSupply;
    address private owner;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor() {
        tokenName = "REWARD_TOKEN";
        symbol = "RCX";
        decimal = 18;
        owner = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        require(_amount <= balanceOf[msg.sender], "insufficient funds");
        updateBalance(_amount, msg.sender, _to);

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function mint(address _to, uint256 _amount) external {
        // Increase the total supply
        _totalSupply += _amount;

        // Assign the minted tokens to the specified account
        balanceOf[_to] += _amount;

        // Emit the Mint event
        emit Transfer(address(0), _to, _amount);
    }

    function approve(address spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        return true;
    }

    function transferFrom(
        address _owner,
        address _recipent,
        uint _numToken
    ) external returns (bool) {
        require(_numToken <= balanceOf[_owner], "Insufficient balance");
        require(
            _numToken <= allowance[owner][msg.sender],
            "Insufficient allowance"
        );
        allowance[_owner][msg.sender] -= _numToken;
        updateBalance(_numToken, _owner, _recipent);
        emit Transfer(_owner, _recipent, _numToken);
        return true;
    }

    function updateBalance(
        uint256 amount,
        address debitAccount,
        address creditAccount
    ) private {
        // Calculate 10% burn amount
        uint256 burnAmount = (amount * 10) / 100;
        // Update balances and total supply
        balanceOf[debitAccount] -= amount + burnAmount;
        balanceOf[creditAccount] += amount;
        _totalSupply -= burnAmount;
    }
}
