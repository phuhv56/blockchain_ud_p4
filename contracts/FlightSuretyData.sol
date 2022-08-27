// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <=0.8.16;

import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        address airlineAddress;
        string name;
        bool active;
        uint256 balance;
        address [] voters;
    }
    mapping(address => Airline) private airlines;
    uint256 private airlineSize = 0;


    struct Flight {
        address airlineAddress;
        string flightNo;
        string origin;
        string destination;
        bool active;
        string status;
        uint256 depatureTime;
    }
    mapping(bytes32 => Flight) private flights;
    uint256 private flightSize = 0; 

    struct Passenger {
        address passengerAddress;
        mapping(bytes32 => uint256) flightInsurances;
        uint256 balance;
    }
    mapping(address => Passenger) private passengers;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }


    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address airlineAddress, 
                                string memory airlineName,
                                address sender
                            )
                            external requireIsOperational
    {
        Airline storage airline = airlines[airlineAddress];
        airline.airlineAddress = airlineAddress;
        airline.name = airlineName;
        airline.active = true;
        airlineSize = airlineSize + 1;
    }

    modifier isAirline(address airlineAddress) {
        require(airlines[airlineAddress].active, 'Is not an airline');
        _;
    }

    function registerFlight
                            (   
                                address airlineAddress,
                                string memory flightNo, 
                                string memory origin, 
                                string memory destination, 
                                uint256 departureTime
                            )
                            external requireIsOperational
    {
        bytes32 key = keccak256(abi.encodePacked(airlineAddress, flightNo)); 
        Flight storage flight = flights[key];
        flight.airlineAddress = airlineAddress;
        flight.flightNo = flightNo;
        flight.origin = origin;
        flight.destination = destination;
        flight.depatureTime = departureTime;
        flight.active = true;
        flightSize = flightSize + 1;

    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                address airlineAddress,
                                address passengerAddress,
                                string memory flightNo,
                                uint256 departureTime,                      
                                uint256 value                  
                            )
                            external
                            payable requireIsOperational
    {
        bytes32 key = getFlightKey(airlineAddress, flightNo, departureTime); 
        if (passengers[passengerAddress].passengerAddress == passengerAddress) {
            passengers[passengerAddress].flightInsurances[key] = value;
        } else {
            Passenger storage passenger = passengers[passengerAddress];
            passenger.flightInsurances[key] = value;
        }
        airlines[flights[key].airlineAddress].balance = airlines[flights[key].airlineAddress].balance.add(value);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                requireIsOperational 
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address payable passengerAddress
                            )
                            external
                            requireIsOperational
    {
        uint256 amount = passengers[passengerAddress].balance;
        passengers[passengerAddress].balance = 0;
        passengerAddress.transfer(amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address airlineAddress,
                                uint256 value
                            )
                            public
                            payable requireIsOperational
    {
        airlines[airlineAddress].balance = airlines[airlineAddress].balance.add(value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable 
    {
    }

    function authorizeCaller(address callerAddress) public {}
}

