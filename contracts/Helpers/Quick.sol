//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Quicksort {
    function getHighest(uint256[] memory data)
        internal
        pure
        returns (uint256 highest)
    {
        if (data.length > 1) {
            highest = _getHighest(data, 0, data.length - 1);
        }
    }

    function getDescending(uint256[] memory data)
        internal
        pure
        returns (uint256[] memory ascending)
    {
        if (data.length > 1) {
            ascending = _getDescending(data, 0, data.length - 1);
        }
    }

    function _getHighest(
        uint256[] memory data,
        uint256 low,
        uint256 high
    ) internal pure returns (uint256) {
        if (low < high) {
            uint256 pivotVal = data[(low + high) / 2];

            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1] < pivotVal) low1++;
                while (data[high1] > pivotVal) high1--;
                if (low1 >= high1) return (high1);
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) _getHighest(data, low, high1);
            high1++;
            if (high1 < high) _getHighest(data, high1, high);
        }
    }

    function _getDescending(
        uint256[] memory data,
        uint256 low,
        uint256 high
    ) internal pure returns (uint256[] memory) {
        if (low < high) {
            uint256 pivotVal = data[(low + high) / 2];

            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1] < pivotVal) low1++;
                while (data[high1] > pivotVal) high1--;
                if (low1 >= high1) return (data);
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) _getDescending(data, low, high1);
            high1++;
            if (high1 < high) _getDescending(data, high1, high);
        }
    }
}
