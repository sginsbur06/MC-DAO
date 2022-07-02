//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface TokenInterface {

    function balanceOf(address _owner) external returns (uint256 balance);

    function transfer(address _to, uint256 _amount) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);

    function approve(address _spender, uint256 _amount) external returns (bool success);

    function setDAO(address payable _dao) external;

    function allowance(
        address _owner,
        address _spender
    ) external returns (uint256 remaining);

    function createToken(address _tokenHolder) external payable returns (bool success);

    function withdraw() external returns (bool _success);

    event CreatedToken(address indexed to, uint amount);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
      
}