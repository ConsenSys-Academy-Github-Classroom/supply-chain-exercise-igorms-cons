pragma solidity >=0.5.16 <0.9.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract ThrowTestSupplyChain {
    SupplyChain public supplyChain;

    constructor(SupplyChain _target) public {
        supplyChain = _target;
    }

    function() external payable {}

    function addItem(string memory name, uint price) public {
        supplyChain.addItem(name, price);
    }

    function itemBuy(uint sku, uint amount) public returns (bool) {
        (bool success, ) = address(supplyChain).call.value(amount).gas(5000)(
            abi.encodeWithSignature("buyItem(uint)", sku)
        );
        return success;
    }

    function shipItem(uint sku) public returns (bool) {
        (bool success, ) = address(supplyChain).call(
            abi.encodeWithSignature("shipItem(uint)", sku)
        );
        return success;
    }

    function receiveItem(uint sku) public returns (bool) {
        (bool success, ) = address(supplyChain).call(
            abi.encodeWithSignature("receiveItem(uint)", sku)
        );
        return success;
    }
}
