var SwapContract = artifacts.require("Swap");

contract("SwapContract", (accounts) => {
  var creatorAddress = accounts[0];
  var firstOwnerAddress = accounts[1];
  var secondOwnerAddress = accounts[2];
  var externalAddress = accounts[3];
  var unprivilegedAddress = accounts[4];
  /* create named accounts for contract roles */

  before(async () => {
    /* before tests */
  });

  beforeEach(async () => {
    /* before each context */
  });

  it("Swap Check...", () => {
    return SwapContract.deployed()
      .then((instance) => {
        return instance.swap(
          {
            path: [
              "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
              "0x71bC5dBdf71add8a92a44B5BEA33f36Dd2503db3",
            ],
            amount: 100000000,
            minReturn: 1,
          },
          {
            APIKey: "2121211215152",
          },
          {
            from: creatorAddress,
          }
        );
      })
      .then((result) => {
        assert.fail();
      })
      .catch((error) => {
        assert.notEqual(error.message, "assert.fail()", "Reason ...");
      });
  });
});
