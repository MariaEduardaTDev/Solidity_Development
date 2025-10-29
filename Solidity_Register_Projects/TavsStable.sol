// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract TAVSStable is ERC20, AutomationCompatibleInterface {

    AggregatorV3Interface public priceFeed;

    uint256 public constant COLLATERAL_RATIO = 150; // colateral de 150%
    uint256 public constant DATAFEED_PRICE_DECIMALS = 8; // preço em 8 casa decimais
    uint256 public constant DECIMALS_FACTOR = 100; // valor em 2 casas decimais
    
    address public liquidationAddress;

    // Posição do usuário
    struct Position {
        uint256 collateralETH; // quantos ETH depositou
        uint256 stablecoinDebt; // a dívida em stablecoin, em 2 casas decimais 
    }
    mapping(address => Position) public positions;
    address[] public users; // lista de endereços de usuários que criram uma dívida
    mapping(address => bool) private userExists;

    event Deposit(address indexed user, uint256 ethAmount , uint256 mintAmount); // toda vez que um usuário deposita ETH e quanto emitido
    event Burn(address indexed user, uint256 burnAmount, uint256 ethReturned); // devolução da stablecoin ou usuário liquidado
    event Liquidated(address indexed user, uint256 collateralSeized); // na liquidação, quanto de colateral perdeu

    constructor() ERC20("TAVS Stable", "TAVST") {
        /**
        * Network: Ethereum Sepolia
        * Aggregator: ETH/USD
        * Other Data Feeds:
        https://docs.chain.link/data-feeds/price-feeds/addresses
        */
        address _priceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeed = AggregatorV3Interface(_priceFeedAddress); // retorno do ETH, na liquidação do usuário, para a carteira do criador da stablecoin

        address _liquidationAddress = msg.sender;
        liquidationAddress = _liquidationAddress;
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }

    function estimateMintAmount(uint256 ethAmount) public view returns (uint256) { // estima quantidade de stablecoin vai ser emitida com base na quantidade de ETH
        uint256 ethPrice = getLatestPrice(); // obtem opreço mais atual do ETH
        uint256 DECIMALS = 10 ** uint256(decimals());
        uint256 ethValueInUSD = (ethAmount * ethPrice * DECIMALS) / 1e8 / 1e18; // converte a quantidade de ETH em USD
        return ethValueInUSD * 100 / COLLATERAL_RATIO; // quantidade em USD que pode ser emitida em stablecoin
    }

    //Depositar ETH e mintar TAVST
    function depositAndMint() external payable {
        require(msg.value > 0, "Must deposit ETH");
        
        uint256 mintAmount = estimateMintAmount(msg.value); 
        _mint(msg.sender, mintAmount);

        if (positions[msg.sender].collateralETH == 0){
            if(!userExists[msg.sender]) {
                users.push(msg.sender);
                userExists[msg.sender] = true;
            }
        }

        positions[msg.sender].collateralETH += msg.value; // acrescenta a quantidade em ETH
        positions[msg.sender].stablecoinDebt += mintAmount; // emite a dívida do usuário
        emit Deposit(msg.sender, msg.value, mintAmount); // emite o depósito
    }

    function estimateWithdrawETH(uint256 burnAmount) public view returns (uint256) {
        require(burnAmount > 0, "Amount must be greater than 0");
        uint256 ethPrice = getLatestPrice();

        // Converter burnAmount (2 decimais) em USD inteiro (18 decimais)
        uint256 burnUSD = (burnAmount * 1e18) / DECIMALS_FACTOR;

        // Adiciona a proporção entre o colateral e o empréstimo de 150% (multiplica por 150 e divide por 100
        uint256 collateralUSD = (burnUSD * COLLATERAL_RATIO) / 100;

        // Converte o USD em ETH: ETH = (USD * 1e8) / priceFeed (com 8 casas decimais)
        uint256 ethToReturn = (collateralUSD * 1e8) / ethPrice;
        return ethToReturn;
    }

    // Queimar TAVST e saca o ETH correspondente 
    function burnAndWithdraw(uint256 burnAmount) external {
        require(balanceOf(msg.sender) >= burnAmount, "Insufficient TAVST");

        uint256 ethToReturn = estimateWithdrawETH(burnAmount);

        // uint256 usdValue = (burnAMount * COLLATERAL_RATIO) / DECIMALS_FACTOR;
        require(positions[msg.sender].collateralETH >= ethToReturn, "Not enough collateral");

        positions[msg.sender].collateralETH -= ethToReturn;
        positions[msg.sender].stablecoinDebt -= burnAmount;
        _burn(msg.sender, burnAmount);

        payable(msg.sender).transfer(ethToReturn);
        emit Burn(msg.sender, burnAmount, ethToReturn); 
    }

    // Oracle da Chainlink
    function getLatestPrice() public view returns (uint256) {
        (, int price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // em 8 casas decimais
    }

    // Obter o colateral do ususário em USD
    function getUserCollateralUSD(address user) public view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        Position memory pos = positions[user];

        uint256 DECIMALS = 10 ** uint256(decimals());
        uint256 collateralUSD = (pos.collateralETH * ethPrice * DECIMALS) / 1e8 / 1e18;
        return collateralUSD;
    }

    // Calcula a razão de garantia do usuário
    function getCollateralRatio(address user) public view returns (uint256) {
        Position memory pos = positions[user];
        if (pos.stablecoinDebt == 0) return type(uint256).max;

        uint256 collateralUSD = getUserCollateralUSD(user);

        //uint256 collateralUSD = (pos.collateralETH * ethPrice) / 1e8;
        //return (collateralUSD * DECIMALS_FACTOR) / pos.stablecoinDebt;
        return collateralUSD / pos.stablecoinDebt;
    }

    // Automação Chainlink: Verifica usuários com colateral insuficiente
    function checkUpkeep (bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (getCollateralRatio(user) < COLLATERAL_RATIO) { // se a quantidade de colateral for menor do que 150%
                upkeepNeeded = true; // usuário é liquidado
                performData = abi.encode(user); // infomra o endereço do usuáro a ser liquidado
                return (true, performData); 
            }
        } // * "for" - utilizado somente para sistemas com poucos usuários*
        return (false, bytes(""));
    }

    // Liquidar usuário com colateral Insuficiente 
    function performUpkeep(bytes calldata performData) external override {
        address user = abi.decode(performData, (address));
        require(getCollateralRatio(user) < COLLATERAL_RATIO, "User not liquidatable");

        // se o usuário for liquidado:
        Position memory positionUser = positions[user]; // obtém a sua posição
        _burn(user, positionUser.stablecoinDebt); // queima a sua dívida em stablecoin

        uint256 collateralETH = positions[user].collateralETH; // obtém a quantidade de colateral e zera as posições
        positions[user].collateralETH = 0;
        positions[user].stablecoinDebt = 0;
        payable(liquidationAddress).transfer(collateralETH); 
        emit Liquidated(user, collateralETH);
    }

    // Listar todos os usuários (para testes e debugging)
    function getUsers() external view returns (address[] memory) {
        return users;
    }
     
     // Permite que o contrato receba ETH
     receive() external payable {} // *Arrumar para que os ETH não fiquem perdidos no contrato*

}

