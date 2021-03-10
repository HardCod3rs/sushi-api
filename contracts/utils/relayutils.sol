contract relayutils {
    // Relayers
    mapping(address => bool) Relayers;

    modifier onlyRelayers() {
        require(Relayers[msg.sender], "Not a Relayer!");
        _;
    }
}
