// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract VRFD20 is VRFConsumerBaseV2Plus {
    // Events
    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    // Các biến cấu hình
    uint256 s_subscriptionId =
        80173977270964330899107741151047707129974488304831960640051107256857184047709;
    address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 s_keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Các biến lưu trữ trạng thái
    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    constructor() VRFConsumerBaseV2Plus(vrfCoordinator) {}

    uint256 private constant ROLL_IN_PROGRESS = 42;

    function rollDice(
        address roller
    ) public onlyOwner returns (uint256 requestId) {
        require(s_results[roller] == 0, "Already rolled");

        // Sẽ thất bại nếu tài khoản đăng ký chưa được thiết lập và cấp vốn.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS; // Đánh dấu đang chờ kết quả
        emit DiceRolled(requestId, roller);
        return requestId;
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // Chuyển đổi kết quả thành một số từ 1 đến 20
        uint256 d20Value = (randomWords[0] % 20) + 1;

        // Gán kết quả cho người chơi tương ứng với requestId
        s_results[s_rollers[requestId]] = d20Value;

        // Phát sự kiện báo xúc xắc đã có kết quả
        emit DiceLanded(requestId, d20Value);
    }

    // Get the result of a dice roll for the caller
    function getResult(address player) public view returns (uint256) {
        return s_results[player];
    }

    // Get the house (contract owner)
    // function getHouse() public view returns (address) {
    //     return s_owner;
    // }

    function house(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");

        return getHouseName(s_results[player]);
    }

    function getHouseName(uint256 id) private pure returns (string memory) {
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];
        return houseNames[id - 1];
    }
}
