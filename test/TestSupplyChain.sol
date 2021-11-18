pragma solidity >=0.5.16 <0.9.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./ThrowTestSupplyChain.sol";

contract TestSupplyChain {
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    ThrowTestSupplyChain public sellerSPProxy;
    ThrowTestSupplyChain public buyerSPProxy;
    ThrowTestSupplyChain public unknownProxy;
    SupplyChain public supplyChain;
    uint public initialBalance = 1 ether;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    uint skuItem = 0;
    uint priceItem = 1000;
    uint excessAmount = 2000;

    function() external payable {}

    function beforeEach() public {
        supplyChain = new SupplyChain();
        sellerSPProxy = new ThrowTestSupplyChain(supplyChain);
        buyerSPProxy = new ThrowTestSupplyChain(supplyChain);
        unknownProxy = new ThrowTestSupplyChain(supplyChain);
        sellerSPProxy.addItem("book", priceItem - 1);
    }

    function checkState(uint _sku) public view returns (uint) {
        string memory name;
        uint sku;
        uint price;
        uint state;
        address seller;
        address buyer;

        (name, sku, price, state, seller, buyer) = supplyChain.fetchItem(_sku);
        return state;
    }

    function testCheckState() public {
        uint res = checkState(skuItem);
        Assert.equal(res, uint(State.ForSale), "for sale!");
    }

    // itemBuy
    // test for failure if user does not send enough funds
    function testNotEnoughFunds() public {
        Assert.isFalse(buyerSPProxy.itemBuy(skuItem, 999), "Fail to pay");
        Assert.equal(checkState(skuItem), uint(State.ForSale), "for sale!");
    }

    // test for purchasing an item that is not for Sale
    function testNotForSale() public {
        Assert.isTrue(buyerSPProxy.itemBuy(skuItem, excessAmount), "Paid");
        Assert.notEqual(
            checkState(skuItem),
            uint(State.ForSale),
            "not for sale!"
        );
        Assert.isFalse(
            buyerSPProxy.itemBuy(skuItem, excessAmount),
            "cant buy this item"
        );
    }

    // shipItem
    // test for calls that are made by not the seller
    function testCallNotSeller() public {
        Assert.isTrue(buyerSPProxy.itemBuy(skuItem, excessAmount), "Paid");
        Assert.isFalse(
            unknownProxy.shipItem(skuItem),
            "cant ship if not seller"
        );
        Assert.equal(
            checkState(skuItem),
            uint(State.Sold),
            "item still sold"
        );
    }

    // test for trying to ship an item that is not marked Sold
    function testShipNotSold() public {
        Assert.isFalse(sellerSPProxy.shipItem(skuItem), "cant ship");
    }

    // receiveItem
    // test calling the function from an address that is not the buyer
    function testCallNotBuyer() public {
        Assert.isTrue(buyerSPProxy.itemBuy(skuItem, excessAmount), "Paid");
        Assert.isTrue(sellerSPProxy.shipItem(skuItem), "shipped");
        Assert.isFalse(
            unknownProxy.receiveItem(skuItem),
            "cant receive if not buyer"
        );
        Assert.equal(
            checkState(skuItem),
            uint(State.Shipped),
            "still shipped state"
        );
    }

    // test calling the function on an item not marked Shipped
    function testCallNotShipped() public {
        Assert.isTrue(buyerSPProxy.itemBuy(skuItem, priceItem), "Paid");
        Assert.isFalse(
            buyerSPProxy.receiveItem(skuItem),
            "cant receive if sold"
        );
        Assert.equal(checkState(skuItem), uint(State.Sold), "still sold");
    }
}
