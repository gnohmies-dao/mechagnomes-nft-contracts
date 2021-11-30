pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC165, ERC721, ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721Pausable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MechaGnomesNFT is ERC721Pausable, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public immutable totalMintSupply = 7654;

    uint256 public immutable protocolReserveCount = 250;

    uint256 internal mintPrice;
    uint256 public maxMintPerTx = 10;

    uint256 internal whitelistSaleStartTime;
    uint256 internal whitelistSaleDuration;
    uint256 internal whitelistReserveCount;
    uint256 internal whitelistMintCount;

    uint256 internal publicSaleStartTime;
    uint256 internal publicSaleDuration;

    bool internal whitelistSaleActive;
    bool internal publicSaleActive;

    string private baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 _mintPrice
    ) ERC721(name, symbol) {
        baseURI = uri;
        mintPrice = _mintPrice;
    }

    modifier canMint(uint256 amount) {
        require(isWhitelistSale() || isPublicSale(), "validation_error:canMint:no_active_sale");
        require(amount > 0, "validation_error:canMint:amount_leq_zero");
        require(totalSupply().add(amount) <= totalMintSupply.sub(protocolReserveCount), "validation_error:canMint:exceeds_total_supply");
        require(maxMintPerTx <= amount, "validation_error:canMint:exceeds_maxMintPerTx");
        if(isWhitelistSale()) {
            require(whitelistReserveCount >= amount, "validation_error:canMint:exceeds_whitelistReserveCount");
        }
        _;
    }

    function isWhitelistSale()
        public
        view
        returns (bool)
    {
        return whitelistSaleActive;
    }

    function isPublicSale()
        public
        view
        returns (bool)
    {
        return publicSaleActive;
    }

    function getMintPrice()
        public
        view
        returns (uint256)
    {
        return mintPrice;
    }

    function setMintPrice(uint256 price)
        external
        onlyOwner
    {
        require(price >= 0 && price != mintPrice, "validation_error:setMintPrice:price_zero_or_set");
        mintPrice = price;
    }

    function withdraw()
        external
        onlyOwner
    {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mint(uint256 amount)
        external
        payable
        canMint(amount)
        nonReentrant
    {
        uint256 _mintCost = mintPrice * amount;
        require(_mintCost <= msg.value, "validation_error:mint:invalid_ether_amount");

        bool whitelistSale = isWhitelistSale();

        for(uint256 i = 0; i < amount; i++) {
            uint256 index = totalSupply().add(1);
            if(whitelistSale) whitelistReserveCount--;
            _safeMint(msg.sender, index);
        }

        if (msg.value > _mintCost) {
            Address.sendValue(payable(msg.sender), msg.value.sub(_mintCost));
        }
    }

    function startWhitelist(uint256 duration, uint reserveCount)
        external
        onlyOwner
    {
        require(!isWhitelistSale() && !isPublicSale(), "validation_error:startWhiteList:existing_sale_running");
        require(duration >= 0, "validation_error:startWhiteList:duration_zero");
        require(reserveCount > 0, "validation_error:startWhiteList:reserveCount_zero");
        whitelistReserveCount = reserveCount;
        whitelistSaleStartTime = block.timestamp;
        whitelistSaleDuration = duration;
        whitelistSaleActive = true;
    }

    function startPublicSale(uint256 duration)
        external
        onlyOwner
    {
        require(!isPublicSale(), "validation_error:startWhiteList:existing_sale_running");
        require(duration >= 0, "validation_error:startWhiteList:duration_zero");
        whitelistSaleActive = false;
        whitelistReserveCount = 0;
        publicSaleStartTime = block.timestamp;
        publicSaleDuration = duration;
        publicSaleActive = true;
    }

    function getElapsedSaleTime()
        internal
        view
        returns (uint256)
    {
        return publicSaleActive ? (publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0)
            : (whitelistSaleStartTime > 0 ? block.timestamp - whitelistSaleStartTime : 0);
    }

    function getRemainingSaleDuration()
        external
        view
        returns (uint256)
    {
        if(!whitelistSaleActive && !publicSaleActive) return 0;
        uint256 elapsedTime = getElapsedSaleTime();
        if ((whitelistSaleActive && elapsedTime >= whitelistSaleDuration)
            || (publicSaleActive && elapsedTime >= publicSaleDuration)) {
            return 0;
        }
        uint256 startTime = whitelistSaleActive ? whitelistSaleStartTime : publicSaleActive ? publicSaleStartTime : 0;
        uint256 duration = whitelistSaleActive ? whitelistSaleDuration : publicSaleActive ? publicSaleDuration : 0;
        return duration == 0 ? 0 : startTime.add(duration).sub(block.timestamp);
    }

    function getRemainingMintable()
        external
        view
        returns (uint256)
    {
        return whitelistSaleActive ? whitelistReserveCount : (totalMintSupply.sub(totalSupply()).sub(protocolReserveCount));
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory uri)
        external
        onlyOwner
    {
        baseURI = uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
