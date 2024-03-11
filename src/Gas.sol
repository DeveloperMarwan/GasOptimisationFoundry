// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract Constants {
    uint8 constant tradeFlag = 1;
    uint8 constant dividendFlag = 1;
}

contract GasContract is Ownable, Constants {
    uint256 private totalSupply = 0; // cannot be updated
    uint8 wasLastOdd = 1;

    address public contractOwner;

    address[5] public administrators;

    //mapping(address => uint256) public isOddWhitelistUser;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        address sender;
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        if (checkForAdmin(msg.sender) || msg.sender == contractOwner) {
            _;
        } else {
            revert(); 
        }
    }

    modifier checkIfWhiteListed(address sender) {
        require(msg.sender == sender);
        uint256 usersTier = whitelist[msg.sender];
        require(usersTier > 0);
        require(usersTier < 4);
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) payable {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[ii], totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
            unchecked {
                ++ii;
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        admin_ = false;
        for (uint256 ii = 0; ii < administrators.length; ) {
            if (administrators[ii] == _user) {
                admin_ = true;
            }
            unchecked {
                ++ii;
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getTradingMode() public pure returns (bool mode_) {
        mode_ = false;
        if (tradeFlag == 1 || dividendFlag == 1) {
            mode_ = true;
        } 
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount
        );
        require(
            bytes(_name).length < 9
        );
        unchecked {
            balances[senderOfTx] -= _amount;
            balances[_recipient] += _amount;
        }
        emit Transfer(_recipient, _amount);
        status_ = true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(
            _tier < 255
        );
        if (_tier >= 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] = 2;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;    
        require(
            balances[senderOfTx] >= _amount
        );
        require(
            _amount > 3
        );
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, 0, msg.sender, true);
        balances[senderOfTx] -= (_amount - whitelist[senderOfTx]);
        balances[_recipient] += (_amount - whitelist[senderOfTx]);
        
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}