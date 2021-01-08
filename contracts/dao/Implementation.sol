/*
    Copyright 2020 Yum Devs Team, based on the works of the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Market.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "../Constants.sol";

contract Implementation is State, Bonding, Market, Regulator, Govern {
    using SafeMath for uint256;

    address private firstTrigger; // address is the first call advance

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize() initializer public {
        mintToAccount(0xF2b2644862950FC2d2D770ffbe64bfDcba8570f3,  1150e18);
    }

    function incentive(address _trigger) private {
        uint256 incentive = Constants.getAdvanceIncentive();
        mintToAccount(msg.sender, incentive);
        emit Incentivization(msg.sender, incentive);
    }

    function advance() external {
        if (firstTrigger != address(0)) {
            Bonding.step();
            Regulator.step();
            Market.step();

            emit Advance(epoch(), block.number, block.timestamp);

            // mint to the first one
            incentive(firstTrigger);
            incentive(msg.sender);

            firstTrigger = address(0);
        } else {
            Require.that(
                epochTime() > epoch(),
                "Bonding",
                "Still current epoch"
            );

            firstTrigger = msg.sender;
        }
    }
}
