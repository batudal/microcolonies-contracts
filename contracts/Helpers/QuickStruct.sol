//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library QuickStruct {
    struct Participant {
        address p_address;
        uint256 p_score;
    }

    function getDescendingStruct(Participant[] memory data)
        internal
        pure
        returns (Participant[] memory ascending)
    {
        if (data.length > 1) {
            ascending = _getDescendingStruct(data, 0, data.length - 1);
        }
    }

    function _getDescendingStruct(
        Participant[] memory data,
        uint256 low,
        uint256 high
    ) internal pure returns (Participant[] memory) {
        if (low < high) {
            uint256 pivotVal = data[(low + high) / 2].p_score;
            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1].p_score < pivotVal) low1++;
                while (data[high1].p_score > pivotVal) high1--;
                if (low1 >= high1) return (data);
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) _getDescendingStruct(data, low, high1);
            high1++;
            if (high1 < high) _getDescendingStruct(data, high1, high);
        }
    }
}
