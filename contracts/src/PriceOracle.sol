// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint8);
}

contract PriceOracle {
    AggregatorV3Interface public immutable feed;
    uint256 public immutable staleAfter;

    error StalePrice();
    error InvalidPrice();

    constructor(address _feed, uint256 _staleAfter) {
        feed = AggregatorV3Interface(_feed);
        staleAfter = _staleAfter;
    }

    function getPrice() external view returns (uint256 price, uint8 decimals) {
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();

        if (answer <= 0) revert InvalidPrice();

        if (block.timestamp - updatedAt > staleAfter) {
            revert StalePrice();
        }

        return (uint256(answer), feed.decimals());
    }
}
