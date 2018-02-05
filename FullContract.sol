pragma solidity ^0.4.18;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract BrixbyToken is Pausable {
    // Public variables of the token
    string public name = "BRIXBY Token";
    string public symbol = "BRICK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

    /**
    * Constrctor function
    *
    * Initializes contract with initial supply tokens to the creator of the contract
    */
    function BrixbyToken(uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;
        // Give the creator all initial tokens
    }

    /**
    * What is the balance of a particular account?
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * Internal transfer, only can be called by this contract
    */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
    * Transfer tokens
    *
    * Send `_value` tokens to `_to` from your account
    *
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transfer(address _to, uint256 _value) public whenNotPaused {
        _value = _value * 10 ** uint256(decimals);
        _transfer(msg.sender, _to, _value);
    }

    /**
    * Transfer tokens from other address
    *
    * Send `_value` tokens to `_to` in behalf of `_from`
    *
    * @param _from The address of the sender
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        _value = _value * 10 ** uint256(decimals);

        require(_value <= allowed[_from][msg.sender]);
        // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
    * Set allowance for other address
    *
    * Allows `_spender` to spend no more than `_value` tokens in your behalf
    *
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * Set allowance for other address and notify
    *
    * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
    *
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    * @param _extraData some extra information to send to the approved contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public whenNotPaused returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
    * Destroy tokens
    *
    * Remove `_value` tokens from the system irreversibly
    *
    * @param _value the amount of money to burn
    */
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);
        // Check if the sender has enough
        balances[msg.sender] -= _value;
        // Subtract from the sender
        totalSupply -= _value;
        // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
    * Destroy tokens from other account
    *
    * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    *
    * @param _from the address of the sender
    * @param _value the amount of money to burn
    */
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[_from] >= _value);
        // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);
        // Check allowance
        balances[_from] -= _value;
        // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;
        // Subtract from the sender's allowance
        totalSupply -= _value;
        // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

interface token {
    function transfer(address receiver, uint amount);
}

contract BrixbyCrowdsale is Pausable {
    address public beneficiary;
    uint public amountRaised;
    uint public tokenAmountRaised;
    uint public startTime;
    uint public deadline;
    uint public price;
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
    function BrixbyCrowdsale(address ifSuccessfulSendTo, uint deadlineTime, uint szaboCostOfEachToken, address addressOfTokenUsedAsReward) {
        beneficiary = ifSuccessfulSendTo;
        deadline = deadlineTime;
        price = szaboCostOfEachToken * 1 szabo;
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
        tokenReward.transfer(msg.sender, tokenAmount);
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
            tokenAmount = tokenAmount + (tokenAmount * 50 / 100);
        }
        else if ((now >= startTime + 1 days) && (now < startTime + 2 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 45 / 100);
        }
        else if ((now >= startTime + 2 days) && (now < startTime + 3 days))
        {
            tokenAmount = tokenAmount + (tokenAmount * 43 / 100);
        }
        //1514073600 - 24.12.2017 00:00
        //1514246399 - 25.12.2017 23:59
        //1515283200 - 07.01.2017 00:00
        //1515455999 - 08.01.2017 23:59
        else if ((now > 1514073600 && now < 1514246399) || (now > 1515283200 && now < 1515455999))
        {
            tokenAmount = tokenAmount + (tokenAmount * 50 / 100);
        }
        else
        {
            tokenAmount = tokenAmount + (tokenAmount * 40 / 100);
        }

        return tokenAmount;
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
}
