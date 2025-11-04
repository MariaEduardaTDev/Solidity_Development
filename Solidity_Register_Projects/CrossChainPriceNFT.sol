// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Importanto contratos da OpenZeppelin
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.6.0/utils/Base64.sol";

// Importando contratos da Chainlink
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CrossChainPriceNFT is ERC721, ERC721URIStorage { // URI: endereço que aponta para os metadados do token ERC721
    // bibliotecas usadas como herança
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenIdCounter;

    // Criar price feed
    AggregatorV3Interface internal priceFeed;
    uint256 public lastPrice = 0;

    // Emojis indicadores de preço
    string priceIndicatorUp = unicode"😀";
    string priceIndicatorDown = unicode"😔";
    string priceIndicatorFlat = unicode"😑";
    string public priceIndicator;


    struct ChainStruct {
        uint64 code; // chain selector
        string name; // nome da blockchain
        string color;
    }
    mapping (uint256 => ChainStruct) chain;

    //https://docs.chain.link/ccip/supported-networks/testnet
    constructor() ERC721 ("CrossChain Price", "CCPrice") {
        chain[0] = ChainStruct ({ // Na 1ª blockchain 
            code: 16015286601757825753,
            name: "Sepolia", // rede Sepolia 
            color: "#0000ff" // Cor azul
        });
        chain[1] = ChainStruct ({ // Na 2ª blockchain
            code: 14767482510784806043,
            name: "Fuji", // rede Fuji
            color: "#ff0000" // Cor vermelha 
        });

        // https://docs.chain.link/data-feeds/price-feeds/addresses
        priceFeed = AggregatorV3Interface(
            // Sepolia 
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43 // endereço do par BTC/USD
        );

        // Emitir o NFT
        mint(msg.sender);
    }

    function mint(address to) public {
        // Emitir NFT da rede Sepolia = chain[0]
        mintFrom(to, 0);
    }

    function mintFrom(address to, uint256 sourceId) public {
        // sourceId: 0 - Sepolia | 1 - Fuji
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        updateMetaData(tokenId, sourceId);
        tokenIdCounter.increment();
    }

    // Atualizar os Metadados
    function updateMetaData(uint256 tokenId, uint256 sourceId) public {
        // criando o texto da imagem SVG
        string memory finalSVG = buildSVG(sourceId);

        // Base64 para codificar o SVG
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Cross-chain Price SVG",',
                        '"description": "SVG NFTs in different chains",',
                        '"image": "data:image/svg+xml;base64,', 
                        Base64.encode(bytes(finalSVG)), '",',
                        '"attributes": [',
                        '{"trait_type": "source",',
                        '"value": "', chain[sourceId].name , '"},',
                        '{"trait_type": "price",',
                        '"value": "', lastPrice.toString() ,'"}',
                     ']}'
                    )
                )
            )
        );

        // Criando o token URI - endereço que aponta para os metadados do NFT
    string memory finalTokenURI = string(
        abi.encodePacked("data:application/json;base64,", json)
        );
        // Definir o endereço (URI) dos metadados do NFT
        _setTokenURI(tokenId, finalTokenURI);
    }

    // Contruindo o SVG string
    function buildSVG(uint256 sourceId) internal returns (string memory) {

        // Criando SVG retângulo com uma cor aleatória
        string memory headSVG = string(
            abi.encodePacked(
                 "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svgjs='http://svgjs.com/svgjs' width='500' height='500' preserveAspectRatio='none' viewBox='0 0 500 500'> <rect width='100%' height='100%' fill='",
                chain[sourceId].color, // cor do fundo do emoji de acordo com a blockchain (sourceId)
                "' />"
            )
        );
        // Atualizando o emoji baseado no preço do BTC
         string memory bodySVG = string(
            abi.encodePacked(
                "<text x='50%' y='50%' font-size='128' dominant-baseline='middle' text-anchor='middle'>",
                comparePrice(),
                "</text>"
            )
        ); 
        // Fechando SVG
        string memory tailSVG = "</svg>";

        // Unindo os textos SVG (SVG strings)
        string memory _finalSVG = string(
            abi.encodePacked(headSVG, bodySVG, tailSVG)
        );
        return _finalSVG;
    }

    // Comparando o novo preço com o preço anterior
    function comparePrice() public returns (string memory) {
        uint256 currentPrice = getChainlinkDataFeedLatestAnswer();
        if(currentPrice > lastPrice) {
            priceIndicator = priceIndicatorUp;
        }
        else if (currentPrice < lastPrice) {
            priceIndicator = priceIndicatorDown;
        }
        else {
            priceIndicator = priceIndicatorFlat;
        }

        lastPrice = currentPrice;
        return priceIndicator;
    }


    // Coleta o último preço (mais atual) do BTC 
    function getChainlinkDataFeedLatestAnswer() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // Devolve o link (URI) com as informações (json) do NFT
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Destrói a NFT completamente do contrato e seus metadados
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}