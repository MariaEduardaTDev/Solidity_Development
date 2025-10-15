//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; ///Interface preparada para ler as funções do Data feeds

interface TokenInterface { /// Chamando somente a função "mint" da interface
    function mint(address account, uint256 amount) external; /// Cria tokens e envia para um endereço a quantidade solicitada
}

contract TokenShop {
    AggregatorV3Interface internal priceFeed; 
    TokenInterface public minter;
    uint256 public tokenPrice = 1000; /// 1 token = 10.00 usd, com 2 casas decimais
    address public owner;

    constructor(address tokenAddress){
        minter = TokenInterface(tokenAddress);
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // Network: Sepolia | Aggregator: ETH/USD | Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        owner = msg.sender; /// o dono é o criador do contrato
    }

    function getChainLinkDataFeedsLatestAnswer() public view returns (int) {
        (
        /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData(); /// Atribui a variável "price" o último valor calculado pelo Chainlink Data Feeds
        return price;
    }

    function tokenAmount(uint256 amountETH) public view returns (uint256) {
        uint256 ethUsd = uint256(getChainLinkDataFeedsLatestAnswer()); /// Atribui a variável "ethUsd" o último valor do ether em usd
        uint256 amountUSD = amountETH * ethUsd / 10**18; /// Multiplica o valor do ether (em 18 casas decimais) pela quantidade e atribui para a variável "amountUSD" 
        uint256 amountToken = amountUSD / tokenPrice / 10**(8/2); /// Converte a quantidade de tokens que podem ser comprados com o quantidade de dólar - ajustando as 8 casas decimais do ETH/USD e 2 casas para o token (10**4)        return amountToken;
        return amountToken; /// Retorna a quantidade de tokens
    }

    receive() external payable {/// Torna o contrato apto a receber transações de pagamentos
        uint256 amountToken = tokenAmount(msg.value); /// Calcula a quantidade de tokens que irá receber pela quantidade de ether enviada
        minter.mint(msg.sender, amountToken); /// o "minter" autoriza a execução da função mint, que cria os tokens calculados e envia ao endereço do msg.sender (comprador) a quantidade de tokens (amountToken)
    }

    modifier onlyOwner() {
        require(msg.sender == owner); /// Apenas o dono do contrato pode executar
        _; /// Segue com o código
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance); /// Envia todo o saldo em ETH recebido pelo contrato e envia para o endereço do dono do contrato
    }

}