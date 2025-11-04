// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Client - armazena os tipos de dados usados
import {Client} from "@chainlink/contracts-ccip@1.6.1/contracts/libraries/Client.sol";
// CCIPReceiver - torna o contrato compativel com o roteador da Chainlink para receber mensagens
import {CCIPReceiver} from "@chainlink/contracts-ccip@1.6.1/contracts/applications/CCIPReceiver.sol";


// Interface para realizar somente a função mintFrom
interface InftMinter {
    function mintFrom(address account, uint256 sourceId) external;
}


contract CrossDestinationMinter is CCIPReceiver {
    InftMinter public nft;

    // Evento para emitir quando a função mintFrom for chamada com sucesso
    event MintCallSuccessfull();
    // https://docs.chain.link/ccip/supported-networks/testnet
    address routerEthereumSepolia = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;

    constructor(address nftAddress) CCIPReceiver(routerEthereumSepolia) {
        nft = InftMinter(nftAddress);
    }

    // função exata "_ccipReceive" para que o roteador possa identificar e enviar as mensagens
    function _ccipReceive(
        Client.Any2EVMMessage memory message // Estrutura de mensagem
    ) internal override {
        (bool success, ) = address(nft).call(message.data); // chama no endereço do NFT e executa o comando "mintFrom" que está no campo "data"
        require(success);
        emit MintCallSuccessfull();
    }

    function testMint() external {
        // Emite da Sepolia - Ethereum Blockchain
        nft.mintFrom(msg.sender, 0);
    }

    // teste da mensagem
    function testMessage() external {
        // Emite da rede Sepolia - Ethereum Blockchain
        bytes memory message;
        message = abi.encodeWithSignature("mintFrom(address,uint256)", msg.sender, 0);

        (bool success, ) = address(nft).call(message);
        require(success);
        emit MintCallSuccessfull();
    }

    function updateNFT(address nftAddress) external {
        nft = InftMinter(nftAddress);
    }

}