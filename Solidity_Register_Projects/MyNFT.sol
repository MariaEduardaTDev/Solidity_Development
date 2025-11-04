//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Importando o básico da biblioteca OpenZeppelin - somente o storage e contadores (para admin os IDs)
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

contract MyNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    // Informações dos metadados para cada etapa do NFT no IPFs
    string[] public MetadataUriList;

    constructor() ERC721("NFT Dog Tiberio", "DOTI"){
    }

    // Função para mintar o NFT
    function safeMint(address to, string memory metadataUri) public { // O link URI indica o endereço de onde estão os metadados do NFT no arquivo json off-chain 
        uint256 tokenId = tokenIdCounter.current(); // pega o último token ID
        tokenIdCounter.increment(); // incrementa +1 ao contador de IDs do token emitidos
        _safeMint(to, tokenId); // Realiza a transferencia do token ao endereço
        MetadataUriList.push(metadataUri); 
        _setTokenURI(tokenId, metadataUri); // Atualiza o token ID
    }

    // Função que permite atualizar a imagem ou outros metadados do NFT
    function updateTokenURI(uint256 tokenId, string memory metadataUri) public {
        _setTokenURI(tokenId, metadataUri);
    }

    // Retorna qual é o URI (o caminho) dos metadados, nesse caso a imagem
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Função override exigida pela Solidity
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super ._burn(tokenId);
    }
}