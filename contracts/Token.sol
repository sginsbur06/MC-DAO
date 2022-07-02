//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenInterface.sol";
import "./DAO.sol";


contract Token is TokenInterface {

    string public name;
    string public symbol;
    uint  public decimals;

    uint256 public totalSupply;

    address public admin;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    DAO dao;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint _decimalPlaces) {

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalPlaces;
        admin = msg.sender;
    }

    modifier onlyTokenholders {
        require(balanceOf(msg.sender) != 0, "Not a tokenHolder");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    function setDAO(address payable _dao) external onlyAdmin {
        dao = DAO(_dao);
    }

    function createToken(address _tokenHolder) public payable returns (bool success) {
        require(msg.value > 0, "No payment"); 

        balances[_tokenHolder] += msg.value;
        totalSupply += msg.value;

        emit CreatedToken(_tokenHolder, msg.value);

        return true;
    }

    function withdraw() public onlyTokenholders returns (bool _success) {

        dao.unVoteAll();
        
        uint balanceOfSender = balances[msg.sender];
        
        uint fundsToWithdraw = (balanceOfSender * address(this).balance) / totalSupply;
        balances[msg.sender] = 0;

        payable(msg.sender).transfer(fundsToWithdraw);
        
        totalSupply -= balanceOfSender;
        
        emit Transfer(msg.sender, address(0), balanceOfSender);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) external returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && !dao.changeOrGetBlocked(msg.sender)
            && !dao.changeOrGetBlocked(_to)) 
           {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;

            emit Transfer(msg.sender, _to, _amount);

            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && !dao.changeOrGetBlocked(_to)
            && !dao.changeOrGetBlocked(_from)) {
               

            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;

            emit Transfer(_from, _to, _amount);

            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

}