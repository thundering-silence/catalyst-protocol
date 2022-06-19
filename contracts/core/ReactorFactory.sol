pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./Reactor.sol";

contract ReactorFactory is Ownable {

    mapping(address => address) public reactors;
    mapping(address => uint) public nonces;

    event ReactorBuilt(address indexed owner, address indexed reactor);
    event ReactorAbandoned(address indexed owner, address indexed reactor);

    function build(address _implementation) public {
        require(reactors[_msgSender()] != address(0), "ReactorFactory: Reactor already exists, abandon it first");
        bytes memory data = bytes('');
        ERC1967Proxy reactor =  new ERC1967Proxy(_implementation, data);
        address payable reactorAddress = payable(reactor);
        Reactor(reactorAddress).transferOwnership(_msgSender());

        reactors[_msgSender()] = reactorAddress;
        nonces[_msgSender()]++;

        emit ReactorBuilt(_msgSender(), address(reactor));
    }

    function abandon() public {
        emit ReactorAbandoned(_msgSender(), reactors[_msgSender()]);
        reactors[_msgSender()] = address(0);
    }

}
