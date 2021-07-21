//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

//main contract
contract BUC {
    //ERC20

    // Public variables of the token
    string public name = "Basic Univesal Coin";
    string public symbol = "BUC";
    uint256 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 private TS = 10**9 * 10**(decimals);

    // This creates an array with all balances
    mapping(address => uint256) private balance;

    // this is to create a map for allows
    mapping(address => mapping(address => uint256)) private allow;

    //storing time of latest tx for each address
    mapping(address => uint256) private time;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //emits total supply whenever its updated
    event Tsupply(
        uint256 indexed _tsup
    );

    //time stamp of each day begining
    uint256 tstamp;

    //total share ,that is 100% in the economy with (decimals) decimal places
    uint256 Tshare = 100 * 10**(decimals);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        balance[msg.sender] = Tshare; // Give the creator all stake(100%)
        tstamp = now;
        for (uint256 i = 0; i < 100; i++) {
            enqueue(10**(decimals));
        }
    }

    //function to display total supply
    function totalSupply() public view returns (uint256) {
        return TS;
    }

    function balanceOf(address account) public view returns (uint256) {
        return (balance[account] * TS) / (10**20);
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allow[_owner][_spender];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 _val;

        //converting value to share
        _val = ((_value * ((10**(decimals)) * 100)) / TS);

        //checking for 0 tranfer
        require(_val != 0, "not enough stake to transfer");

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        // Check if the sender has enough stake
        require(balance[_from] >= _val);

        // Check for overflows
        require(balance[_to] + _val >= balance[_to]);

        // Save this for an assertion in the future
        uint256 previousBalances = balance[_from] + balance[_to];

        //updating time of their latest transaction
        time[msg.sender] = now;

        //calling velocity update avg velocity
        velocity(_value);

        // Subtract from the sender
        balance[_from] -= _val;

        // Add the same to the recipient
        balance[_to] += _val;

        //cleaning accounts if less amount available in senders wallet
        if (balance[_from] < 100) {
            balance[_to] += balance[_from];
            delete balance[_from];
        }

        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balance[_from] + balance[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send '_value' tokens to '_to' from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send '_value' tokens to '_to' on behalf of '_from'
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allow[_from][msg.sender]); // Check allow
        allow[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allow for other address
     *
     * Allows '_spender' to spend no more than '_value' tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allow[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //traded volume in one day
    uint256 public supply;

    //velocity of one day
    uint256 public Velocity;

    //avg Velocity of 100 days
    uint256 public avgVel = 10**(decimals);

    //queue data structure to store the 100 latest velocities
    mapping(uint256 => uint256) public queue;

    //sum of 100 velocity
    uint256 private VeloSum = 100 * (10**(decimals));

    //Initializing values to finrst and last
    uint256 first = 1;
    uint256 last = 0;

    //function to add elements into queue
    function enqueue(uint256 _velocity) internal {
        last += 1;
        queue[last] = _velocity;
    }

    //function to delete elements form queue
    function dequeue() internal {
        require(last >= first); // non-empty queue
        delete queue[first];
        first += 1;
    }

    function velocity(uint256 _value) public {
        if (now - tstamp < 180) {
            //stores that days trade volume
            supply += _value;
        } else if (now - tstamp >= 180) {
            
            tstamp = now;

            //calculating Velocity of that day
            Velocity = ((supply * 10**(decimals)) / TS);
            
            VeloSum = VeloSum + Velocity - queue[first];

            avgVel = (VeloSum/100);

            //adding new element to queue
            enqueue(Velocity);

            //deleting first element
            dequeue();

            //Initializes supply to 0
            supply = 0;

            //updating TS
            if (avgVel > 10**(decimals)) {
                TS += (((avgVel - 10**(decimals)) * TS) / 10**(decimals));
                emit Tsupply(TS);
            } else if (avgVel < 10**(decimals)) {
                uint256 uSupply = (TS -
                    (((10**(decimals) - avgVel) * TS) / 10**(decimals)));
                if (uSupply > (10**9 * 10**(decimals))) {
                    TS = uSupply;
                    emit Tsupply(TS);
                }
                emit Tsupply(TS);
            }
            else{
                emit Tsupply(TS);
            }
        }
    }

    //function to mine tokens
    function mine(address _lost) public {
        require((now - time[_lost]) > 63072000, "this address isnt lost");
        balance[msg.sender] += balance[_lost];
        delete balance[_lost];
        delete time[_lost];
    }
}
