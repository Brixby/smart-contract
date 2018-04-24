pragma solidity ^0.4.18;

import 'github.com/Brixby/smart-contract/v2/Pausable.sol';

interface token {
    function transfer(address receiver, uint amount);

    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BrixbyCrowdsale is Pausable {
    address public beneficiary;
    uint public amountRaised;
    uint public tokenAmountRaised;
    uint public startTime;
    uint public deadline;
    uint public price;
    uint public priceUsd;
    uint public exchangeRate;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = true;

    event FundTransfer(address backer, uint amount, bool isContribution);
    event Deadline(address beneficiary, uint amountRaised);

    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }

    /**
    * Constrctor function
    *
    * Setup the owner
    */
    function BrixbyCrowdsale(address ifSuccessfulSendTo, uint deadlineTime, uint usdCostOfEachToken, address addressOfTokenUsedAsReward) {
        beneficiary = ifSuccessfulSendTo;
        deadline = deadlineTime;
        setPriceUsd(usdCostOfEachToken);
        tokenReward = token(addressOfTokenUsedAsReward);
        pause();
    }

    /**
    * Fallback function
    *
    * The function without name is the default function that is called whenever anyone sends funds to a contract
    */
    function() payable {
        require(!crowdsaleClosed);
        require(msg.value >= price);
        if (now > deadline)
        {
            closeCrowdsaleByDeadline();
        }

        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        uint tokenAmount = getTokenAmountWithDiscount(amount, price);
        tokenAmountRaised += tokenAmount;
        transferToken(msg.sender, tokenAmount, false);

        //in
        FundTransfer(msg.sender, amount, true);
        forwardFunds(amount);
    }

    /**
    * Return amount of tokens with discount
    */
    function getTokenAmountWithDiscount(uint amount, uint price) public returns (uint)
    {
        uint tokenAmount = amount / price;

        //discount by amount
        if (amount > (60 * 1 ether))
        {
            tokenAmount = tokenAmount + (tokenAmount * 100 / 100);
        }
        else if ((amount > (50 * 1 ether)) && (amount <= (60 * 1 ether)))
        {
            tokenAmount = tokenAmount + (tokenAmount * 80 / 100);
        }
        else if ((amount > (40 * 1 ether)) && (amount <= (50 * 1 ether)))
        {
            tokenAmount = tokenAmount + (tokenAmount * 70 / 100);
        }
        else if ((amount > (30 * 1 ether)) && (amount <= (40 * 1 ether)))
        {
            tokenAmount = tokenAmount + (tokenAmount * 60 / 100);
        }

        //discount by days
        else if (now < startTime + 1 days)
        {
            tokenAmount = tokenAmount + (tokenAmount * 40 / 100);
        }
        else if ((now >= startTime + 1 days) && (now < startTime + 2 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 35 / 100);
        }
        else if ((now >= startTime + 2 days) && (now < startTime + 3 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 30 / 100);
        }
        else if ((now >= startTime + 3 days) && (now < startTime + 4 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 25 / 100);
        }
        else if ((now >= startTime + 4 days) && (now < startTime + 5 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 20 / 100);
        }

        return tokenAmount;
    }

    /**
    * Setting usd-eth exchange rate (how much is one ether in dollars)
    */
    function setExchangeRate(uint _rateInUsd) whenNotPaused onlyOwner public {
        exchangeRate = _rateInUsd;
        updatePrice();
    }

    /**
    * Update price for 1 token in ether
    */
    function updatePrice() internal {
        price = (priceUsd / exchangeRate) * 1 ether;
    }

    /**
    * Setting price for 1 token in usd
    */
    function setPriceUsd(uint _price) whenNotPaused onlyOwner public {
        priceUsd = _price;
        updatePrice();
    }

    /**
    * Start sale
    */
    function startCrowdsale() whenPaused onlyOwner public {
        crowdsaleClosed = false;
        startTime = now;
        unpause();
    }

    /**
    * Close sale
    */
    function closeCrowdsale() whenNotPaused onlyOwner {
        crowdsaleClosed = true;
        pause();
    }

    function closeCrowdsaleByDeadline() whenNotPaused afterDeadline {
        Deadline(beneficiary, amountRaised);
        crowdsaleClosed = true;
        pause();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds(uint amount) internal {
        beneficiary.transfer(amount);
        FundTransfer(beneficiary, amountRaised, false);
    }

    function transferTokenToWallet(address _address, uint256 _value, bool _isPercent) onlyOwner payable {
        require(_value > 0);
        transferToken(_address, _value, _isPercent);
    }

    function transferTokenToWalletList(address[] _addresses, uint256 _value, bool _isPercent) onlyOwner {
        require(_value > 0);
        for (uint i = 0; i < _addresses.length; i++) {
            transferToken(_addresses[i], _value, _isPercent);
        }
    }

    function transferToken(address _address, uint256 _value, bool _isPercent) internal {
        if (_isPercent)
        {
            //getBalance in Ether because BrixbyToken storage in Ether
            uint256 balance = tokenReward.balanceOf(_address) / 1 ether;
            uint256 newValue = balance * _value / 100;
            tokenReward.transfer(_address, newValue);
        }
        else
        {
            tokenReward.transfer(_address, _value);
        }
    }
}
